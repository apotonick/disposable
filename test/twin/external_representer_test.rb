require "test_helper"

class ExternalRepresenterOnTwinTest < MiniTest::Spec
  module Model
    Song  = Struct.new(:id, :title, :album, :composer)
    Album = Struct.new(:id, :name, :songs, :artist)
    Artist = Struct.new(:id)
  end

  require "disposable/twin/sync"
  require "disposable/twin/save"
  module Twin
    class Album < Disposable::Twin
      property :id
      property :name
      collection :songs, :twin => lambda { |*| Song }
      property :artist, twin: lambda { |*| Artist }

      extend Representer
      include Setup
      include Sync
      include Save
    end

    class Song < Disposable::Twin
      property :id
      property :composer, :twin => lambda { |*| Artist }

      extend Representer
      include Setup
      include Sync
      include Save
    end

    class Artist < Disposable::Twin
      property :id

      extend Representer
      include Setup
      include Sync
      include Save
    end
  end

  let (:song) { Model::Song.new(1, "Broken", nil) }
  let (:composer) { Model::Artist.new(2) }
  let (:song_with_composer) { Model::Song.new(3, "Resist Stance", nil, composer) }
  let (:artist) { Model::Artist.new(9) }

  # FIXME: AllowSymbol (at least in Decorator) is not treated as feature and not inherited to inlines.
  # TODO: prepopulation (e.g. always one composer more.) - wait, this is UI-specific and goes to Form.

  # ok, now let's submit a form/PUT/POST with a 3rd song plus composer.
  # this representer will/can be automatically infered from the Twin/contract.
  class RepresentableDecorator < Representable::Decorator
    include Representable::Hash
    include AllowSymbols

    property :name
    collection :songs, pass_options: true,

            instance: lambda { |fragment, index, options|
              collection = options.binding.get

              (item = collection[index]) ? item : collection.for_model(Model::Song.new) },
            setter: lambda { |collection, *| songs.replace collection } do
       include AllowSymbols
      property :id
      # DISCUSS: what's a bit confusing is that for property we can add a model, in collection we need to twin it.
      #   what about collection[index]= Model::Song.new without the :setter ?
      property :composer, pass_options: true,
            instance: lambda { |fragment, options|
              (item = options.binding.get) ? item : Model::Artist.new } do
        include AllowSymbols
        property :id
      end
    end
  end

  describe "" do
    let (:album) { Model::Album.new(nil, nil, [song, song_with_composer], artist) }

    it do
      twin = Twin::Album.new(album)

      puts "original: #{twin.songs[0].inspect}"
      song1_id = twin.songs[0].object_id

      RepresentableDecorator.new(twin).from_hash({
        name: "Live In A Dive",
        songs: [
          {id: 1}, # old
          {id: 3}, # no composer this time?
          {id: "Talk Show"}, # new one.
          {id: "Kinetic", composer: {id: "Osker"}}
        ]
      })

puts "==> original: #{twin.songs[0].inspect}"

      twin.name.must_equal "Live In A Dive"
      twin.songs.size.must_equal 4
      twin.songs[0].id.must_equal 1
      twin.songs[0].object_id.must_equal song1_id
      twin.songs[1].id.must_equal 3
      twin.songs[2].id.must_equal "Talk Show"
      twin.songs[3].id.must_equal "Kinetic"
      twin.songs[3].composer.id.must_equal "Osker"
      # composer is not attached to song model, yet.
      twin.songs[3].send(:model).composer.must_equal nil


      # nothing has changed in the model, yet.
      album.songs.size.must_equal 2


      twin.save


      # # this usually happens in Contract::Validate or in from_* in a representer
      # twin.name = "Live And Dangerous"
      # twin.songs[0].id = 1
      # twin.songs[1].id = 2
      # twin.songs[1].composer.id = 3
      # twin.artist.id = "Thin Lizzy"

      # # not written to model, yet.
      # album.name.must_equal nil
      # album.songs[0].id.must_equal nil
      # album.songs[1].id.must_equal nil
      # album.songs[1].composer.id.must_equal nil
      # album.artist.id.must_equal nil

      # twin.sync

      # album.name.must_equal "Live And Dangerous"

      # album.songs[1].composer.id.must_equal 3
      # album.artist.id.must_equal "Thin Lizzy"
    end
  end
end