require "test_helper"
require "disposable/twin/callback"

class CallbacksTest < MiniTest::Spec
  before do
    @invokes = []
  end

  attr_reader :invokes

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
  Callback = Disposable::Twin::Callback::Runner
    # collection :songs do
    #   after_add    :song_added! # , context: :operation
    #   after_create :notify_album!
    #   after_remove :notify_artist!
    # end

  let (:twin) { AlbumTwin.new(album) }

  describe "#on_create" do
    let (:album) { Album.new }

    # after initialization
    it do
      invokes = []
      Callback.new(twin).on_create { |t| invokes << t }
      invokes.must_equal []
    end

    # save, without any attributes changed.
    it do
      twin.save

      invokes = []
      Callback.new(twin).on_create { |t| invokes << t }
      invokes.must_equal [twin]
    end

    # before and after save, with attributes changed
    it do
      # state change, but not persisted, yet.
      twin.name = "Run For Cover"
      invokes = []
      Callback.new(twin).on_create { |t| invokes << t }
      invokes.must_equal []

      twin.save

      Callback.new(twin).on_create { |t| invokes << t }
      invokes.must_equal [twin]
    end

    # for collections.
    it do
      album.songs << song1 = Song.new
      album.songs << Song.create(title: "Run For Cover")
      album.songs << song2 = Song.new
      invokes = []

      Callback.new(twin.songs).on_create { |t| invokes << t }
      invokes.must_equal []

      twin.save

      Callback.new(twin.songs).on_create { |t| invokes << t }
      invokes.must_equal [twin.songs[0], twin.songs[2]]
    end
  end

  describe "#on_update" do
    let (:album) { Album.new }

    # after initialization.
    it do
      invokes = []
      Callback.new(twin).on_update { |t| invokes << t }
      invokes.must_equal []
    end

    # single twin.
    # on_update only works on persisted objects.
    it do
      twin.name = "After The War" # change but not persisted

      invokes = []
      Callback.new(twin).on_update { |t| invokes << t }
      invokes.must_equal []

      invokes = []
      twin.save

      Callback.new(twin).on_update { |t| invokes << t }
      invokes.must_equal []


      # now with the persisted album.
      twin = AlbumTwin.new(album) # Album is persisted now.

      Callback.new(twin).on_update { |t| invokes << t }
      invokes.must_equal []

      invokes = []
      twin.save

      # nothing has changed, yet.
      Callback.new(twin).on_update { |t| invokes << t }
      invokes.must_equal []

      twin.name= "Corridors Of Power"

      # this will even trigger on_update before saving.
      Callback.new(twin).on_update { |t| invokes << t }
      invokes.must_equal [twin]

      invokes = []
      twin.save

      # name changed.
      Callback.new(twin).on_update { |t| invokes << t }
      invokes.must_equal [twin]
    end

    # for collections.
    it do
      album.songs << song1 = Song.new
      album.songs << Song.create(title: "Run For Cover")
      album.songs << song2 = Song.new

      invokes = []
      Callback.new(twin.songs).on_update { |t| invokes << t }
      invokes.must_equal []

      invokes = []
      twin.save

      # initial save is no update.
      Callback.new(twin.songs).on_update { |t| invokes << t }
      invokes.must_equal []


      # now with the persisted album.
      twin = AlbumTwin.new(album) # Album is persisted now.

      Callback.new(twin.songs).on_update { |t| invokes << t }
      invokes.must_equal []

      invokes = []
      twin.save

      # nothing has changed, yet.
      Callback.new(twin.songs).on_update { |t| invokes << t }
      invokes.must_equal []

      twin.songs[1].title= "After The War"
      twin.songs[2].title= "Run For Cover"

      # # this will even trigger on_update before saving.
      Callback.new(twin.songs).on_update { |t| invokes << t }
      invokes.must_equal [twin.songs[1], twin.songs[2]]

      invokes = []
      twin.save

      Callback.new(twin.songs).on_update { |t| invokes << t }
      invokes.must_equal [twin.songs[1], twin.songs[2]]
    end
    # it do
    #   album.songs << song1 = Song.new
    #   album.songs << Song.create(title: "Run For Cover")
    #   album.songs << song2 = Song.new
    #   invokes = []

    #   Callback.new(twin.songs).on_create { |t| invokes << t }
    #   invokes.must_equal []

    #   twin.save

    #   Callback.new(twin.songs).on_create { |t| invokes << t }
    #   invokes.must_equal [twin.songs[0], twin.songs[2]]
    # end
  end


  describe "#on_add" do
    let (:album) { Album.new }

    # empty collection.
    it do
      invokes = []
      Callback.new(twin.songs).on_add { |t| invokes << t }
      invokes.must_equal []
    end

    # collection present on initialize are not added.
    it do
      ex_song = Song.create(title: "Run For Cover")
      song    = Song.new
      album.songs = [ex_song, song]

      Callback.new(twin.songs).on_add { |t| invokes << t }
      invokes.must_equal []
    end

    # items added after initialization are added.
    it do
      ex_song = Song.create(title: "Run For Cover")
      song    = Song.new
      album.songs = [ex_song]

      twin.songs << song

      Callback.new(twin.songs).on_add { |t| invokes << t }
      invokes.must_equal [twin.songs[1]]

      twin.save

      # still shows the added after save.
      invokes = []
      Callback.new(twin.songs).on_add { |t| invokes << t }
      invokes.must_equal [twin.songs[1]]
    end
  end


  # it do
  #   artist  = Artist.new
  #   ex_song = Song.create(title: "Run For Cover")
  #   song    = Song.new
  #   album   = Album.new(artist: artist, songs: [ex_song, song])


  #   twin = AlbumTwin.new(Album.new)

  #   twin.songs << ex_song
  #   twin.songs << song

  #   twin.save

  #   # Callback.new(twin).(self) # operation: self, other: context

  #   Callback.new(twin).on_update { |song| updated!(song) }
  #   Callback.new(twin).on_create { |song| created!(song) }

  #   Callback.new(twin.songs).on_add { |song| flush_cache!(song) }



  #   twin.songs.added.each do |song|
  #     puts song if song.changed?(:persisted?) # after_create
  #     # puts song.inspect if !song.persisted?
  #   end
  # end
  #     def flush_cache!(twin)
  #     puts "flush_cache! for #{twin}"
  #   end

  #   def updated!(twin)
  #     puts "updated! #{twin}"
  #   end

  #   def created!(twin)
  #     puts "created! #{twin}"
  #   end

end