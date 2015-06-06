# #sync!
#   1. assign scalars to model (respecting virtual, excluded attributes)
#   2. call sync! on nested
#
# Note: #sync currently implicitly saves AR objects with collections
module Disposable::Twin::Sync
  def sync_models(options={})
    return yield to_nested_hash if block_given?

    sync!(options)
  end
  alias_method :sync, :sync_models

  # reading from fields allows using readers in form for presentation
  # and writers still pass to fields in #validate????
  def sync!(options) # semi-public.
    options_for_sync = sync_options(Disposable::Twin::Decorator::Options[options])

    self.class.bla.each do |dfn|
      next if options_for_sync[:exclude].include?(dfn.name.to_sym)

      model.send(dfn.setter, send(dfn.getter)) and next unless dfn[:twin]

      if dfn[:collection]
        arr = send(dfn.getter).collect { |nested_twin| nested_twin.sync!({}) }
        model.send(dfn.setter, arr) # FIXME: override this for different collection syncing.
      else
        next if send(dfn.getter).nil?
        nested_model = send(dfn.getter).sync!({}) # sync.

        model.send(dfn.setter, nested_model)
      end

    end

    model
  end

private
  module ToNestedHash
    def to_nested_hash(*)
      nested_hash_representer.new(self).to_hash
    end

    def nested_hash_representer
      self.class.representer(:nested_hash, all: true) do |dfn|
        dfn.merge!(readable: true)

        dfn.merge!(
          serialize: lambda { |form, args| form.to_nested_hash },
          representable: true # TODO: why do we need that here?
        ) if dfn[:twin]
      end
    end
  end
  include ToNestedHash


  module SyncOptions
    def sync_options(options)
      options
    end
  end
  include SyncOptions

  # This representer inherits from sync_representer and add functionality on top of that.
  # It allows running custom dynamic blocks add with :sync.
  def dynamic_sync_representer
    self.class.representer(:dynamic_sync, superclass: sync_representer, :all => true) do |dfn|
      next unless setter = dfn[:sync]
      dfn.merge!(:setter => Dynamic.new(dfn, setter))
    end
  end


  # Excludes :virtual and :writeable: false properties from #sync in this twin.
  module Writeable
    def sync_options(options)
      options = super

      protected_fields = self.class.bla.find_all { |d| d[:writeable] == false }.collect { |d| d.name.to_sym }
      options.exclude!(protected_fields)
    end
  end
  include Writeable


  # This will skip unchanged properties in #sync. To use this for all nested form do as follows.
  #
  #   class SongForm < Reform::Form
  #     feature Sync::SkipUnchanged
  module SkipUnchanged
    def self.included(base)
      base.send :include, Disposable::Twin::Changed
    end

    def sync_options(options)
      # DISCUSS: we currently don't track if nested forms have changed (only their attributes). that's why i include them all here, which
      # is additional sync work/slightly wrong. solution: allow forms to form.changed? not sure how to do that with collections.
      scalars   = self.class.object_representer_class.representable_attrs.each { |dfn| !dfn[:twin] }.collect { |dfn| dfn.name }
      unchanged = scalars - changed.keys

      # exclude unchanged scalars, nested forms and changed scalars still go in here!
      options.exclude!(unchanged.map(&:to_sym))
      super
    end
  end
end
