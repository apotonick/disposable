require 'test_helper'

class TwinTest < MiniTest::Spec
  module Model
    Song  = Struct.new(:id, :title, :album)
    Album = Struct.new(:id, :name, :songs, :artist)
    Artist = Struct.new(:id)
  end


  module Twin
    class Album < Disposable::Twin
      property :id # DISCUSS: needed for #save.
      property :name
      collection :songs, :twin => lambda { |*| Song }
      property :artist, :twin => lambda { |*| Artist }
    end

    class Song < Disposable::Twin
      property :id # DISCUSS: needed for #save.
      property :name, :from => :title
      property :album, :twin => Album
    end

    class Artist < Disposable::Twin
      property :id

      include Setup
    end
  end

  let (:song) { Model::Song.new(1, "Broken", nil) }

  describe "#initialize" do
    it do
      twin = Twin::Song.new(song)
      song.id = 2
      # :from maps public name
      twin.name.must_equal "Broken" # public: #name
      twin.id.must_equal 2
    end

    # override property with public name in constructor.
    it do
      # override twin's value...
      Twin::Song.new(song, :name => "Kenny").name.must_equal "Kenny"

      # .. but do not write to the model!
      song.title.must_equal "Broken"
    end
  end

  describe "setter" do
    let (:twin) { Twin::Song.new(song) }
    let (:album) { Model::Album.new(1, "The Stories Are True") }

    it do
      twin.id = 3
      twin.name = "Lucky"
      twin.album = album # this is a model, not a twin.

      # updates twin
      twin.id.must_equal 3
      twin.name.must_equal "Lucky"

      # setter for nested property will twin value.
      twin.album.extend(Disposable::Comparable)
      assert twin.album == Twin::Album.new(album) # FIXME: why does must_equal not call #== ?

      # setter for nested collection.

      # DOES NOT update model
      song.id.must_equal 1
      song.title.must_equal "Broken"
    end

    # setters for twin properties return the twin, not the model
    # it do
    #   result = twin.album = album
    #   result.must_equal twin.album
    # end
  end

  # FIXME: experimental.
  describe "#to_s" do
    class HitTwin < Disposable::Twin
      include Setup

      property :song do
      end
    end

    let (:hit) { OpenStruct.new(song: song) }
    it { HitTwin.new(hit).to_s.must_match "#<TwinTest::HitTwin:" }
    it { HitTwin.new(hit).song.to_s.must_match "#<Twin (inline):" }
  end
end


class OverridingAccessorsTest < TwinTest
  # overriding accessors in Twin
  class Song < Disposable::Twin
    property :title

    def title
      super.downcase
    end
  end

  it { Song.new(Model::Song.new(1, "A Tale That Wasn't Right")).title.must_equal "a tale that wasn't right" }
end


require 'disposable/twin/struct'
class TwinStructTest < MiniTest::Spec
  class Song < Disposable::Twin
    include Struct
    property :number, :default => 1 # FIXME: this should be :default_if_nil so it becomes clear with a model.
    option   :cool?
  end

  # empty hash
  it { Song.new({}).number.must_equal 1 }
  # model hash
  it { Song.new(number: 2).number.must_equal 2 }

  # with hash and options as one hash.
  it { Song.new(number: 3, cool?: true).cool?.must_equal true }
  it { Song.new(number: 3, cool?: true).number.must_equal 3 }

  # with model hash and options hash separated.
  it { Song.new({number: 3}, {cool?: true}).cool?.must_equal true }
  it { Song.new({number: 3}, {cool?: true}).number.must_equal 3 }
end


class TwinAsTest < MiniTest::Spec
  module Model
    Song  = Struct.new(:title, :album)
    Album = Struct.new(:name)
  end


  module Twin
    class Album < Disposable::Twin
      property :record_name, :from => :name

      # model Model::Album
    end

    class Song < Disposable::Twin
      property :name, :from => :title
      property :record, :twin => Album, :from => :album

      # model Model::Song
    end
  end

end


class TwinBuilderTest < MiniTest::Spec
  class Twin < Disposable::Twin
    property :id
    property :title
    option   :is_released
  end

  describe "without property setup" do
    class Host
      include Disposable::Twin::Builder

      twin Twin

      def initialize(*args)
        @model = build_twin(*args)
      end

      attr_reader :model
    end

    subject { Host.new(TwinTest::Model::Song.new(1, "Saturday Night"), is_released: true) }

    # model is simply the twin.
    it { subject.respond_to?(:title).must_equal false }
    it { subject.model.id.must_equal 1 }
    it { subject.model.title.must_equal "Saturday Night" }
    it { subject.model.is_released.must_equal true }
  end


  describe "without property setup" do
    class HostWithReaders
      include Disposable::Twin::Builder

      extend Forwardable
      twin(Twin) { |dfn| def_delegator :@model, dfn.name }

      def initialize(*args)
        @model = build_twin(*args)
      end
    end

    subject { HostWithReaders.new(TwinTest::Model::Song.new(1, "Saturday Night"), is_released: true) }

    # both twin gets created and reader method defined.
    it { subject.id.must_equal 1 }
    it { subject.title.must_equal "Saturday Night" }
    it { subject.is_released.must_equal true }
  end
end

# TODO: test coercion!