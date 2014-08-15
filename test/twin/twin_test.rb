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
      property :name, :as => :title
      property :album, :twin => Album

      # model Model::Song
    end
  end

  let (:song) { Model::Song.new(1, "Broken", nil) }

  describe "#initialize" do
    it do
      twin = Twin::Song.new(song)
      song.id = 2
      # :as maps public name
      twin.name.must_equal "Broken" # public: #name
      twin.id.must_equal 2
    end

    # override property with public name in constructor.
    it { Twin::Song.new(song, :name => "Kenny").name.must_equal "Kenny" }
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

    # updates model (directly, per default)
    it { song.id.must_equal 3 }
    it { song.title.must_equal "Lucky" }
  end


  # describe "::new" do # TODO: this creates a new model!
  #   let(:album) { Twin::Album.new }
  #   let (:song) { Twin::Song.new }

  #   it { album.name.must_equal nil }
  #   it { album.songs.must_equal nil }
  #   it { song.title.must_equal nil }
  #   it { song.album.must_equal nil }
  # end


  # describe "::new with arguments" do
  #   let (:talking) { Twin::Song.new("title" => "Talking") }
  #   let (:album) { Twin::Album.new(:name => "30 Years", :songs => [talking]) }
  #   subject { Twin::Song.new("title" => "Broken", "album" => album) }

  #   it { subject.title.must_equal "Broken" }
  #   it { subject.album.must_equal album }
  #   it { subject.album.name.must_equal "30 Years" }
  #   it { album.songs.must_equal [talking] }
  # end


  # describe "::new with :symbols" do
  #   subject { Twin::Song.new(:title => "Broken") }

  #   it { subject.title.must_equal "Broken" }
  #   it { subject.album.must_equal nil }
  # end


  # # DISCUSS: make ::from private.
  # describe "::from" do
  #   let (:song) { Model::Song.new(1, "Broken", album) }
  #   let (:album) { Model::Album.new(2, "The Process Of  Belief", [Model::Song.new(3, "Dr. Stein")]) }

  #   subject {Twin::Song.from(song) }

  #   it { subject.title.must_equal "Broken" }
  #   it { subject.album.must_be_kind_of Twin::Album }
  #   it { subject.album.name.must_equal album.name }
  #   it { subject.album.songs.first.title.must_equal "Dr. Stein" } # TODO: more tests on collections and object identity (if we need that).
  # end
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

# from is as close to from_hash as possible
# there should be #to in a perfect API, nothing else.


# should #new create empty associated models?


class TwinAsTest < MiniTest::Spec
  module Model
    Song  = Struct.new(:title, :album)
    Album = Struct.new(:name)
  end


  module Twin
    class Album < Disposable::Twin
      property :record_name, :as => :name

      # model Model::Album
    end

    class Song < Disposable::Twin
      property :name, :as => :title
      property :record, :twin => Album, :as => :album

      # model Model::Song
    end
  end


  # let (:record) { Twin::Album.new(:record_name => "Veni Vidi Vicous") }
  # subject { Twin::Song.new(:name => "Outsmarted", :record => record) }


  # describe "::new" do # TODO: this creates a new model!
  #   # the Twin exposes the as: API.
  #   it { subject.name.must_equal "Outsmarted" }
  #   it { subject.record.must_equal record }
  # end
end


require 'disposable/twin/option'
class TwinOptionTest < TwinTest
  class Song < Disposable::Twin
    include Option

    property :id # DISCUSS: needed for #save.
    property :title

    option :preview?
    option :highlight?
  end


  describe "::new" do
    let (:song) { Model::Song.new(1, "Broken") }
    let (:twin) { Song.new(song, :preview? => false) }


    it { twin.id.must_equal 1 }
    it { twin.title.must_equal "Broken" }

    # option is not delegated to model.
    it {
      twin.preview?.must_equal false }

    it { Song.new(song, :preview? => true, :highlight => false).preview?.must_equal true }
  end
end







# TODO: test coercion!