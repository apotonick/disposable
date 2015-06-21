require "test_helper"
require "disposable/twin/callback"

class CallbackGroupTest < MiniTest::Spec
  class Group < Disposable::Twin::Callback::Group
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

    # property :email, on_change(:rehash_email!)

    on_change :change!
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
    twin = AlbumTwin.new(Album.new)
    twin.songs << Song.new(title: "Dead To Me")
    twin.songs << Song.new(title: "Diesel Boy")

    Group.new(twin).()
  end

  it do
    twin = AlbumTwin.new(Album.new)
    twin.songs << Song.new(title: "Dead To Me")
    twin.songs << Song.new(title: "Diesel Boy")

    # FIXME #<< SHOULD change!
    twin.name = "Dear Landlord"

    Group.new(twin).()
    # Disposable::Twin::Callback::Dispatch.new(twin).on_change{ |twin| puts twin;puts }
  end
end