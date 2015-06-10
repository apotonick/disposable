require "test_helper"

class PersistedTest < MiniTest::Spec
  class AlbumTwin < Disposable::Twin
    feature Sync, Save
    feature Persisted, Changed

    property :name

    property :artist do
      # on_added
      # on_removed
      property :name
    end

    collection :songs do
      # after_add: could also be existing user
      # after_remove
      # after_create: this means added+changed?(:persisted): song created and added.
      # after_update
      property :title
    end
  end

  it do
    artist  = Artist.new
    ex_song = Song.create(title: "Run For Cover")
    song    = Song.new
    album   = Album.new(artist: artist, songs: [ex_song, song])


    artist.persisted?.must_equal false
    album.persisted?.must_equal false
    ex_song.persisted?.must_equal true
    song.persisted?.must_equal false

    twin = AlbumTwin.new(album)
    twin.persisted?.must_equal false
    twin.changed?(:persisted?).must_equal false
    twin.artist.persisted?.must_equal false
    twin.artist.changed?(:persisted?).must_equal false
    twin.songs[0].persisted?.must_equal true
    twin.songs[0].changed?(:persisted?).must_equal false
    twin.songs[1].persisted?.must_equal false
    twin.songs[1].changed?(:persisted?).must_equal false

    twin.save

    artist.persisted?.must_equal true
    album.persisted?.must_equal true
    ex_song.persisted?.must_equal true
    song.persisted?.must_equal true

    twin.persisted?.must_equal true
    twin.changed?(:persisted?).must_equal true
    twin.artist.persisted?.must_equal true
    twin.artist.changed?(:persisted?).must_equal true
    twin.songs[0].persisted?.must_equal true
    twin.songs[0].changed?(:persisted?).must_equal false
    twin.songs[1].persisted?.must_equal true
    twin.songs[1].changed?(:persisted?).must_equal true
  end


  describe "#created?" do
    it do
      twin = AlbumTwin.new(Album.new)

      twin.created?.must_equal false
      twin.save
      twin.created?.must_equal true
    end

    it do
      twin = AlbumTwin.new(Album.create)

      twin.created?.must_equal false
      twin.save
      twin.created?.must_equal false
    end
  end


  # describe "#updated?" do
  #   it do
  #     twin = AlbumTwin.new(Album.new)

  #     twin.updated?.must_equal false
  #     twin.save
  #     twin.updated?.must_equal false
  #   end

  #   it do
  #     twin = AlbumTwin.new(Album.create)

  #     twin.updated?.must_equal false
  #     twin.save
  #     twin.updated?.must_equal true
  #   end
  # end
end