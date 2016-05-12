require 'test_helper'
# require "representable/debug"

require 'disposable/twin/struct'

class TwinStructTest < MiniTest::Spec
  class Song < Disposable::Twin
    include Struct
    property :number#, default: 1 # FIXME: this should be :default_if_nil so it becomes clear with a model.
    property :cool?
  end

  # empty hash
  # it { Song.new({}).number.must_equal 1 }
  it { Song.new({}).number.must_equal nil } # TODO: implement default.

  # model hash
  it { Song.new(number: 2).number.must_equal 2 }

  # with hash and options as one hash.
  it { Song.new(number: 3, cool?: true).cool?.must_equal true }
  it { Song.new(number: 3, cool?: true).number.must_equal 3 }

  # with model hash and options hash separated.
  it { Song.new({number: 3}, {cool?: true}).cool?.must_equal true }
  it { Song.new({number: 3}, {cool?: true}).number.must_equal 3 }


  describe "writing" do
    let (:song) { Song.new(model, {cool?: true}) }
    let (:model) { {number: 3} }

    # writer
    it do
      song.number = 9
      song.number.must_equal 9
      model[:number].must_equal 3
    end

    # writer with sync
    it do
      song.number = 9
      model = song.sync

      song.number.must_equal 9
      model["number"].must_equal 9

      # song.send(:model).object_id.must_equal model.object_id
    end
  end
end


class TwinWithNestedStructTest < MiniTest::Spec
  class Song < Disposable::Twin
    property :title
    include Sync

    property :options do # don't call #to_hash, this is triggered in the twin's constructor.
      include Struct
      property :recorded
      property :released

      property :preferences do
        include Struct
        property :show_image
        property :play_teaser
      end

      collection :roles do
        include Struct
        property :name
      end
    end
  end

  # FIXME: test with missing hash properties, e.g. without released and with released:false.
  let (:model) { OpenStruct.new(title: "Seed of Fear and Anger", options: {recorded: true, released: 1,
    preferences: {show_image: true, play_teaser: 2}, roles: [{name: "user"}]}) }

  # public "hash" reader
  it { Song.new(model).options.recorded.must_equal true }

  # public "hash" writer
  it {
    song = Song.new(model)

    song.options.recorded = "yo"
    song.options.recorded.must_equal "yo"

    song.options.preferences.show_image.must_equal true
    song.options.preferences.play_teaser.must_equal 2

    song.options.preferences.show_image= 9


    song.sync # this is only called on the top model, e.g. in Reform#save.

    model.title.must_equal "Seed of Fear and Anger"
    model.options["recorded"].must_equal "yo"
    model.options["preferences"].must_equal({"show_image" => 9, "play_teaser"=>2})
  }

  describe "nested writes" do
    let (:song) { Song.new(model) }

    # adding to collection.
    it do
      # note that Struct-twin's public API wants a hash!
      song.options.roles.append({}) # add empty "model" to hash collection.
      song.options.roles[-1].name = "admin"

      song.options.roles.size.must_equal 2
      song.options.roles[0].name.must_equal "user"
      song.options.roles[1].name.must_equal "admin"
      model.options[:roles].must_equal([{:name=>"user"}]) # model hasn't changed, of course.

      song.sync

      model.options.must_equal({"recorded"=>true, "released"=>1, "preferences"=>{"show_image"=>true, "play_teaser"=>2}, "roles"=>[{"name"=>"user"}, {"name"=>"admin"}]})
    end

    # overwriting nested property via #preferences=.
    it do
      song.options.preferences = {play_teaser: :maybe}
      song.sync

      model.options.must_equal({"recorded"=>true, "released"=>1, "preferences"=>{"play_teaser"=>:maybe}, "roles"=>[{"name"=>"user"}]})
    end

    # overwriting collection via #roles=.
    it do
      song.options.roles = [{name: "wizard"}]
      song.sync

      model.options.must_equal({"recorded"=>true, "released"=>1, "preferences"=>{"show_image"=>true, "play_teaser"=>2}, "roles"=>[{"name"=>"wizard"}]})
    end
  end

  # break dance
  # it do
  #   song = Song.new(model)

  #   song.options.roles<<({name: "admin"})

  #   song.sync

  #   model[:options][:roles].must_equal({    })

  #   pp song


  #   song.options.preferences.sync!
  #   song.options.model.must_be_instance_of Hash
  #   song.options.preferences.model.must_be_instance_of Hash


  #   # this must break!
  #   # song.options.preferences = OpenStruct.new(play_teaser: true) # write property object to hash fragment.
  #   # this must break!
  #   song.options.roles = [Struct.new(:name)]
  #   song.options.sync!
  # end


  describe "#save" do
    it { Song.new(model).extend(Disposable::Twin::Save).save }
  end
end

class CompositionWithStructTest < Minitest::Spec
  class PersistedSheet < Disposable::Twin
    feature Sync

    property :content do
      feature Struct

      property :tags
      collection :notes do
        property :text
        property :index
      end
    end
  end

  class Sheet < Disposable::Twin
    include Composition
    feature Sync

    property   :tags,  on: :content #, twin: PersistedSheet.definitions.get[:content].definitions.get(:tags)
    collection :notes, on: :content do
      property :text
      property :index
    end#, twin: PersistedSheet.definitions.get(:content)[:nested].definitions.get(:notes)[:nested]


  end

  class Sheeeeeeet < Disposable::Twin
    feature Sync
    property :content do
      property :tags
      collection :notes do
        property :text
        property :index
      end
    end
  end

  let (:model) do
    OpenStruct.new(
      content: {
        tags:  "#hashtag",
        notes: [
          { text: "Freedom", created_at: nil, index: 0 },
          { text: "Like", created_at: nil, index: 1 },
        ]
      }
    )
  end


  let (:persisted_sheet) { PersistedSheet.new(model) }
  let (:sheet) { Sheet.new(content: persisted_sheet.content) }

  it do
    skip
    # raise persisted_sheet.content.notes[0].inspect

#     sheeet= Sheeeeeeet.new(p= PersistedSheet.new(model))

#     p.content = sheeet.content

# raise
#     sheeet.sync
#     raise




    sheet.tags.must_equal "#hashtag"
    sheet.notes[0].text.must_equal "Freedom"
    sheet.notes[0].index.must_equal 0

    sheet.notes[0].index = 2

    sheet.sync

  end
end
