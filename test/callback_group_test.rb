require "test_helper"
require "disposable/callback"
require "pp"

class CallbackGroupTest < MiniTest::Spec
  class Group < Disposable::Callback::Group
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
    # Disposable::Callback::Dispatch.new(twin).on_change{ |twin| puts twin;puts }

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
    # Disposable::Callback::Dispatch.new(twin).on_change{ |twin| puts twin;puts }

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
  class Group < Disposable::Callback::Group
    on_change :change!
    collection :songs do
      on_add :notify_album!
      on_add :reset_song!
    end
    on_change :rehash_name!, property: :title
    property :artist do
      on_change :sing!
    end
  end

  it do
    Group.hooks.size.must_equal 4
    Group.hooks[0].to_s.must_equal "[:on_change, [:change!]]"
    # Group.hooks[1][1].representer_module.hooks.to_s.must_equal "[[:on_add, [:notify_album!]],[:on_add, [:reset_song!]]]"
    Group.hooks[2].to_s.must_equal "[:on_change, [:rehash_name!, {:property=>:title}]]"

    Group.representer_class.representable_attrs.get(Group.hooks[3][1]).representer_module.hooks.to_s.must_equal "[[:on_change, [:sing!]]]"
  end

  class EmptyGroup < Group
  end



  it do
    EmptyGroup.hooks.size.must_equal 4
    # TODO:
  end

  class EnhancedGroup < Group
    on_change :redo!
    collection :songs do
      on_add :rewind!
    end
  end

  it do
    Group.hooks.size.must_equal 4
    EnhancedGroup.hooks.size.must_equal 6
    EnhancedGroup.representer_class.representable_attrs.get(EnhancedGroup.hooks[5][1]).representer_module.hooks.to_s.must_equal "[[:on_add, [:rewind!]]]"
  end

  class EnhancedWithInheritGroup < EnhancedGroup
    collection :songs, inherit: true do # finds first.
      on_add :eat!
    end
    property :artist, inherit: true do
      on_delete :yell!
    end
  end

  it do
    Group.hooks.size.must_equal 4
    EnhancedGroup.hooks.size.must_equal 6

    EnhancedGroup.representer_class.representable_attrs.get(EnhancedGroup.hooks[5][1]).representer_module.hooks.to_s.must_equal "[[:on_add, [:rewind!]]]"
    EnhancedWithInheritGroup.hooks.size.must_equal 6
    EnhancedWithInheritGroup.representer_class.representable_attrs.get(EnhancedWithInheritGroup.hooks[1][1]).representer_module.hooks.to_s.must_equal "[[:on_add, [:rewind!]], [:on_add, [:eat!]]]"
    EnhancedWithInheritGroup.representer_class.representable_attrs.get(EnhancedWithInheritGroup.hooks[3][1]).representer_module.hooks.to_s.must_equal "[[:on_change, [:sing!]], [:on_delete, [:yell!]]]"
  end

  class RemovingInheritGroup < Group
    remove! :on_change, :change!
    collection :songs, inherit: true do # this will not change position
      remove! :on_add, :notify_album!
    end
  end

# # puts "@@@@@ #{Group.hooks.object_id.inspect}"
# # puts "@@@@@ #{EmptyGroup.hooks.object_id.inspect}"
# puts "@@@@@ Group:         #{Group.representer_class.representable_attrs.get(:songs).representer_module.hooks.inspect}"
# puts "@@@@@ EnhancedGroup: #{EnhancedGroup.representer_class.representable_attrs.get(:songs).representer_module.hooks.inspect}"
# puts "@@@@@ InheritGroup:  #{EnhancedWithInheritGroup.representer_class.representable_attrs.get(:songs).representer_module.hooks.inspect}"
# puts "@@@@@ RemovingGroup: #{RemovingInheritGroup.representer_class.representable_attrs.get(:songs).representer_module.hooks.inspect}"
# # puts "@@@@@ #{EnhancedWithInheritGroup.representer_class.representable_attrs.get(:songs).representer_module.hooks.object_id.inspect}"

  # TODO: object_id tests for all nested representers.

  it do
    Group.hooks.size.must_equal 4
    RemovingInheritGroup.hooks.size.must_equal 3
    RemovingInheritGroup.representer_class.representable_attrs.get(RemovingInheritGroup.hooks[0][1]).representer_module.hooks.to_s.must_equal "[[:on_add, [:reset_song!]]]"
    RemovingInheritGroup.representer_class.representable_attrs.get(RemovingInheritGroup.hooks[2][1]).representer_module.hooks.to_s.must_equal "[[:on_change, [:sing!]]]"
  end

  # Group::clone
  ClonedGroup = Group.clone
  ClonedGroup.class_eval do
    remove! :on_change, :change!
  end

  it do
    Group.hooks.size.must_equal 4
    ClonedGroup.hooks.size.must_equal 3
  end
end