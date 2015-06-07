require "test_helper"

class CallbacksTest < MiniTest::Spec
  class AlbumTwin < Disposable::Twin
    feature Sync
    feature Save
    feature Persisted, Changed

    property :name

    property :artist do
      property :name
    end

    collection :songs do
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
end