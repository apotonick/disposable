require "test_helper"

class TwinSyncTest < MiniTest::Spec
  module Model
    Song  = Struct.new(:title, :composer)
    Album = Struct.new(:name, :songs, :artist)
    Artist = Struct.new(:name)
  end


  module Twin
    class Album < Disposable::Twin
      feature Setup
      feature Sync

      property :name

      collection :songs do
        property :title

        property :composer do
          property :name
        end
      end

      property :artist do
        property :name
      end
    end
  end


  let (:song) { Model::Song.new() }
  let (:composer) { Model::Artist.new(nil) }
  let (:song_with_composer) { Model::Song.new(nil, composer) }
  let (:artist) { Model::Artist.new(nil) }

  # with populated model.
  describe "#sync" do
    let (:album) { Model::Album.new(nil, [song, song_with_composer], artist) }

    it do
      twin = Twin::Album.new(album)

      # this usually happens in Contract::Validate or in from_* in a representer
      twin.name = "Live And Dangerous"
      twin.songs[0].title = "Southbound"
      twin.songs[1].title = "The Boys Are Back In Town"
      twin.songs[1].composer.name = "Lynott"
      twin.artist.name = "Thin Lizzy"

      # not written to model, yet.
      album.name.must_equal nil
      album.songs[0].title.must_equal nil
      album.songs[1].title.must_equal nil
      album.songs[1].composer.name.must_equal nil
      album.artist.name.must_equal nil

      twin.sync

      album.name.must_equal "Live And Dangerous"
      album.songs[0].title.must_equal "Southbound"
      album.songs[1].title.must_equal "The Boys Are Back In Town"
      album.songs[1].composer.name.must_equal "Lynott"
      album.artist.name.must_equal "Thin Lizzy"
    end

    # with empty, not populated model.
    it do
      album = Model::Album.new(nil, [])
      twin  = Twin::Album.new(album)

      # this usually happens in Contract::Validate or in from_* in a representer
      twin.name = "Live And Dangerous"

      twin.songs.insert(0, song)
      twin.songs.insert(1, song_with_composer)

      twin.songs[0].title = "Southbound"
      twin.songs[1].title = "The Boys Are Back In Town"
      twin.songs[1].composer.name = "Lynott"

      # not written to model, yet.
      album.name.must_equal nil
      album.songs.must_equal []
      album.artist.must_equal nil

      twin.sync # this assigns a new collection via #songs=.

      album.name.must_equal "Live And Dangerous"
      album.songs[0].title.must_equal "Southbound"
      album.songs[1].title.must_equal "The Boys Are Back In Town"
      album.songs[1].composer.name.must_equal "Lynott"
    end
  end
end