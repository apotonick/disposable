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
      property :title
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
      twin.title.must_equal "Broken" # public: #record_name
      twin.id.must_equal 1
    end

    # allows passing options.
    it do
      # override twin's value...
      Twin::Song.new(song, :title => "Kenny").title.must_equal "Kenny"

      # .. but do not write to the model!
      song.title.must_equal "Broken"
    end
  end

  describe "setter" do
    let (:twin) { Twin::Song.new(song) }
    let (:album) { Model::Album.new(1, "The Stories Are True") }

    it do
      twin.id = 3
      twin.title = "Lucky"
      twin.album = album # this is a model, not a twin.

      # updates twin
      twin.id.must_equal 3
      twin.title.must_equal "Lucky"

      # setter for nested property will twin value.
      twin.album.extend(Disposable::Comparable)
      assert twin.album == Twin::Album.new(album) # FIXME: why does must_equal not call #== ?

      # setter for nested collection.

      # DOES NOT update model
      song.id.must_equal 1
      song.title.must_equal "Broken"
    end

    describe "deleting" do
      it "allows overwriting nested twin with nil" do
        album = Model::Album.new(1, "Uncertain Terms", [], artist=Model::Artist.new("Greg Howe"))
        twin = Twin::Album.new(album)
        twin.artist.id.must_equal "Greg Howe"

        twin.artist = nil
        twin.artist.must_equal nil
      end
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
# TODO: test coercion!