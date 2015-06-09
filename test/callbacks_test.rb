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

  # - Callbacks don't have before and after. This is up to the caller.
  class Callback
    # collection :songs do
    #   after_add    :song_added! # , context: :operation
    #   after_create :notify_album!
    #   after_remove :notify_artist!
    # end

    def initialize(twin)
      @twin = twin
    end

    def on_add # how to call it once, for "all"?
      @twin.added.each do |item|
        yield if item.changed?(:persisted?) # after_create
      end
    end

    def on_update
      twins = [@twin]

      twins.each do |t|
        next if t.changed?(:persisted?) # that means it was created.
        next unless t.changed?
        yield
      end
    end

    def on_create
      twins = [@twin]

      twins.each do |twin|
        next unless twin.changed?(:persisted?) # this has to be flipped.
        yield twin
      end
    end
  end

  let (:twin) { AlbumTwin.new(album) }

  describe "#on_create" do
    let (:album) { Album.new }

    it do
      invokes = []

      Callback.new(twin).on_create { |t| invokes << t }
      invokes.must_equal []

      twin.save

      Callback.new(twin).on_create { |t| invokes << t }
      invokes.must_equal [twin]
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

    Callback.new(twin).on_update { |song| updated!(song) }
    Callback.new(twin).on_create { |song| created!(song) }

    Callback.new(twin.songs).on_add { |song| flush_cache!(song) }



    twin.songs.added.each do |song|
      puts song if song.changed?(:persisted?) # after_create
      # puts song.inspect if !song.persisted?
    end
  end
      def flush_cache!(twin)
      puts "flush_cache! for #{twin}"
    end

    def updated!(twin)
      puts "updated! #{twin}"
    end

    def created!(twin)
      puts "created! #{twin}"
    end

end