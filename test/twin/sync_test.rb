require "test_helper"

class TwinSyncTest < MiniTest::Spec
  module Model
    Song  = Struct.new(:id, :title, :album, :composer)
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
      include Sync
    end

    class Song < Disposable::Twin
      property :id
      property :composer, :twin => lambda { |*| Artist }

      extend Representer
      include Setup
      include Sync
    end

    class Artist < Disposable::Twin
      property :id

      extend Representer
      include Setup
      include Sync
    end
  end


  let (:song) { Model::Song.new() }
  let (:composer) { Model::Artist.new(nil) }
  let (:song_with_composer) { Model::Song.new(nil, nil, nil, composer) }
  let (:artist) { Model::Artist.new(nil) }

  describe "#sync" do
    let (:album) { Model::Album.new(nil, nil, [song, song_with_composer], artist) }

    it do
      twin = Twin::Album.new(album)

      # this usually happens in Contract::Validate or in from_* in a representer
      twin.name = "Live And Dangerous"
      twin.songs[0].id = 1
      twin.songs[1].id = 2
      twin.songs[1].composer.id = 3
      twin.artist.id = "Thin Lizzy"

      # not written to model, yet.
      album.name.must_equal nil
      album.songs[0].id.must_equal nil
      album.songs[1].id.must_equal nil
      album.songs[1].composer.id.must_equal nil
      album.artist.id.must_equal nil

      twin.sync

      album.name.must_equal "Live And Dangerous"
      album.songs[0].id.must_equal 1
      album.songs[1].id.must_equal 2
      album.songs[1].composer.id.must_equal 3
      album.artist.id.must_equal "Thin Lizzy"
    end
  end
end