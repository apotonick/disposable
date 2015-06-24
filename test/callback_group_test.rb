require "test_helper"
require "disposable/twin/callback"
require "pp"

class CallbackGroupTest < MiniTest::Spec
  class Group < Disposable::Twin::Callback::Group
    attr_reader :output

    on_change :change!

    collection :songs do
      on_add :notify_album!
      on_add :reset_song!

      # on_delete :notify_deleted_author! # in Update!

      def notify_album!(twin)
        @output = "added to songs"
      end

      def reset_song!(twin)
        @output << "added to songs, reseting"
      end
    end

    on_change :rehash_name!, property: :title


    on_create :expire_cache! # on_change
    on_update :expire_cache!

    def change!(twin)
      @output = "Album has changed!"
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

    group.output.must_equal "Album has changed!"
  end

  # context.
  class Operation
    attr_reader :output

    def change!(twin)
      @output = "changed!"
    end

    def notify_album!(twin)
      @output << "notify_album!"
    end

    def reset_song!(twin)
      @output << "reset_song!"
    end
  end

  it do
    twin = AlbumTwin.new(Album.new)
    twin.songs << Song.new(title: "Dead To Me")

    twin.name = "Dear Landlord"

    group = Group.new(twin).(context: context = Operation.new)
    # Disposable::Twin::Callback::Dispatch.new(twin).on_change{ |twin| puts twin;puts }

    # pp group.invocations

    group.invocations.must_equal [
      [:on_change, :change!, [twin]],
      [:on_add, :notify_album!, [twin.songs[0]]],
      [:on_add, :reset_song!,   [twin.songs[0]]],
      [:on_change, :rehash_name!, []],
      [:on_create, :expire_cache!, []],
      [:on_update, :expire_cache!, []],
    ]

    context.output.must_equal "changed!notify_album!reset_song!"
  end
end

class CallbackGroupInheritanceTest < MiniTest::Spec
  class Group < Disposable::Twin::Callback::Group
    on_change :change!
    collection :songs do
      on_add :notify_album!
      on_add :reset_song!
    end
    on_change :rehash_name!, property: :title
  end

  class EmptyGroup < Group
  end

  it do
    EmptyGroup.hooks.size.must_equal 3
  end

  class EnhancedGroup < Group
    on_change :redo!
    collection :songs do
      on_add :rewind!
    end
  end

  it do
    Group.hooks.size.must_equal 3
    EnhancedGroup.hooks.size.must_equal 5
    EnhancedGroup.hooks[4][1].representer_module.hooks.to_s.must_equal "[[:on_add, [:rewind!]]]"
  end

  class EnhancedWithInheritGroup < EnhancedGroup
    collection :songs, inherit: true do # finds first.
      on_add :eat!
    end
  end

  it do
    Group.hooks.size.must_equal 3
    EnhancedGroup.hooks.size.must_equal 5
    EnhancedGroup.hooks[4][1].representer_module.hooks.to_s.must_equal "[[:on_add, [:rewind!]]]"
    # EnhancedWithInheritGroup.hooks[4][1].representer_module.hooks.to_s.must_equal ""
    EnhancedWithInheritGroup.hooks.size.must_equal 5
    EnhancedWithInheritGroup.hooks[1][1].representer_module.hooks.to_s.must_equal "[[:on_add, [:rewind!]], [:on_add, [:eat!]]]"
  end
end