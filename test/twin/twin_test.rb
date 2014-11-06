require 'test_helper'


class TwinTest < MiniTest::Spec
  module Model
    Song  = Struct.new(:id, :title, :album)
    Album = Struct.new(:id, :name, :songs)
  end


  module Twin
    class Album < Disposable::Twin
      property :id # DISCUSS: needed for #save.
      property :name
      collection :songs, :twin => lambda { |*| Song }

      # model Model::Album
    end

    class Song < Disposable::Twin
      property :id # DISCUSS: needed for #save.
      property :name, :from => :title
      property :album, :twin => Album

      # model Model::Song
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

    before do
      twin.id = 3
      twin.name = "Lucky"
    end

    # updates twin
    it { twin.id.must_equal 3 }
    it { twin.name.must_equal "Lucky" }

    # DOES NOT update model
    it { song.id.must_equal 1 }
    it { song.title.must_equal "Broken" }
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


class TwinDecoratorTest < MiniTest::Spec
  subject { TwinTest::Twin::Song.representer_class.new(nil) }

  it { subject.twin_names.must_equal [:album] }
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


class TwinOptionTest < TwinTest
  class Song < Disposable::Twin
    property :id # DISCUSS: needed for #save.
    property :title

    option :preview?
    option :highlight?
  end

  let (:song) { Model::Song.new(1, "Broken") }
  let (:twin) { Song.new(song, :preview? => false) }


  # properties are read from model.
  it { twin.id.must_equal 1 }
  it { twin.title.must_equal "Broken" }

  # option is not delegated to model.
  it { twin.preview?.must_equal false }
  # not passing option means zero.
  it { twin.highlight?.must_equal nil }

  # passing both options.
  it { Song.new(song, preview?: true, highlight?: false).preview?.must_equal true }
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