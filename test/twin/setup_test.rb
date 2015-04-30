require "test_helper"

# TODO: test nested Setup!!!!

class TwinSetupTest < MiniTest::Spec
  module Model
    Song  = Struct.new(:id, :title, :album)
    Album = Struct.new(:id, :name, :songs, :artist)
    Artist = Struct.new(:id)
  end


  module Twin
    class Album < Disposable::Twin
      property :id
      property :name
      collection :songs, :twin => lambda { |*| Song }
      property :artist, twin: lambda { |*| Artist }

      extend Representer
      include Setup
    end

    class Song < Disposable::Twin
      property :id

      extend Representer
      include Setup
    end

    class Artist < Disposable::Twin
      property :id

      extend Representer
      include Setup
    end
  end


  let (:song) { Model::Song.new(1, "Broken", nil) }
  let (:artist) { Model::Artist.new(9) }

  describe "with songs: [song]" do
    let (:album) { Model::Album.new(1, "The Rest Is Silence", [song], artist) }

    it do
      twin = Twin::Album.new(album)

      # raise twin.songs.first.inspect

      twin.songs.size.must_equal 1
      twin.songs[0].must_be_instance_of Twin::Song
      twin.songs[0].id.must_equal 1
      twin.songs.must_be_instance_of Disposable::Twin::Collection
    end
  end

  describe "with songs: [] and artist: nil" do
    let (:album) { Model::Album.new(1, "The Rest Is Silence", [], nil) }

    it do
      twin = Twin::Album.new(album)

      twin.songs.size.must_equal 0
      twin.songs.must_be_instance_of Disposable::Twin::Collection
    end
  end

  # DISCUSS: do we need to cover that (songs: nil in model)?
  # describe "with non-existent :songs" do
  #   let (:album) { Model::Album.new(1, "The Rest Is Silence", nil) }

  #   it do
  #     twin = Twin::Album.new(album)

  #     twin.songs.size.must_equal 0
  #     twin.songs.must_be_instance_of Disposable::Twin::Collection
  #   end
  # end
end