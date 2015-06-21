require "test_helper"
require "disposable/twin/callback"
require "pp"

class CallbackGroupTest < MiniTest::Spec
  class Group < Disposable::Twin::Callback::Group
    on_change :change!

    collection :songs do
      on_add :notify_album!
      on_add :reset_song!

      # on_delete :notify_deleted_author! # in Update!

      def notify_album!(twin)
        puts "added to songs: #{twin.inspect}"
      end

      def reset_song!(twin)
        puts "added to songs, reseting: #{twin.inspect}"
      end
    end

    on_change :rehash_name!, property: :title


    on_create :expire_cache! # on_change
    on_update :expire_cache!

    def change!(twin)
      puts "Album has changed!   -@@@@@ #{twin.inspect}"
    end
  end


  class AlbumTwin < Disposable::Twin
    feature Sync, Save
    feature Persisted, Changed

    property :name

    property :artist do
      property :name
    end

    collection :songs do
      property :title
    end
  end


  # empty.
  it do
    album = Album.new(songs: [Song.new(title: "Dead To Me"), Song.new(title: "Diesel Boy")])
    twin  = AlbumTwin.new(album)

    Group.new(twin).().invocations.must_equal [
      [:on_change, :change!, []],
      [:on_add, :notify_album!, []],
      [:on_add, :reset_song!, []],
      [:on_change, :rehash_name!, []],
      [:on_create, :expire_cache!, []],
      [:on_update, :expire_cache!, []],
    ]
  end

  it do
    twin = AlbumTwin.new(Album.new)
    twin.songs << Song.new(title: "Dead To Me")
    twin.songs << Song.new(title: "Diesel Boy")

    twin.name = "Dear Landlord"

    group = Group.new(twin).()
    # Disposable::Twin::Callback::Dispatch.new(twin).on_change{ |twin| puts twin;puts }

    # pp group.invocations

    group.invocations.must_equal [
      [:on_change, :change!, [twin]],
      [:on_add, :notify_album!, [twin.songs[0], twin.songs[1]]],
      [:on_add, :reset_song!,   [twin.songs[0], twin.songs[1]]],
      [:on_change, :rehash_name!, []],
      [:on_create, :expire_cache!, []],
      [:on_update, :expire_cache!, []],
    ]
  end
end