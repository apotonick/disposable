require "test_helper"

class CallbacksTest < MiniTest::Spec
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

  class Callback
    # collection :songs do
    #   after_add    :song_added! # , context: :operation
    #   after_create :notify_album!
    #   after_remove :notify_artist!
    # end

    def initialize(twin)
      @twin = twin
    end

    def after_add # how to call it once, for "all"?
      @twin.added.each do |item|
        yield if item.changed?(:persisted?) # after_create
      end
    end
  end

  it do
    artist  = Artist.new
    ex_song = Song.create(title: "Run For Cover")
    song    = Song.new
    album   = Album.new(artist: artist, songs: [ex_song, song])


    twin = AlbumTwin.new(Album.new)

    twin.songs << ex_song
    twin.songs << song

    twin.save

    # Callback.new(twin).(self) # operation: self, other: context

    Callback.new(twin.songs).after_add { |song| flush_cache!(song) }



    twin.songs.added.each do |song|
      puts song if song.changed?(:persisted?) # after_create
      # puts song.inspect if !song.persisted?
    end
  end
      def flush_cache!(twin)
      puts "flush_cache! for #{twin}"
    end

end