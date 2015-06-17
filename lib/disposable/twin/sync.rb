# #sync!
#   1. assign scalars to model (respecting virtual, excluded attributes)
#   2. call sync! on nested
#
# Note: #sync currently implicitly saves AR objects with collections
class Disposable::Twin
  module Sync
    def sync_models(options={})
      return yield to_nested_hash if block_given?

      sync!(options)
    end
    alias_method :sync, :sync_models

    # reading from fields allows using readers in form for presentation
    # and writers still pass to fields in #validate????
    def sync!(options) # semi-public.
      options_for_sync = sync_options(Decorator::Options[options])

      schema.each(options_for_sync) do |dfn|
        unless dfn[:twin]
          model.send(dfn.setter, send(dfn.getter)) # always sync the property
          next
        end

        nested_model = PropertyProcessor.new(dfn, self).() { |twin| twin.sync!({}) }

        next if nested_model.nil?

        model.send(dfn.setter, nested_model)
      end

      model
    end

    def self.included(includer)
      includer.extend ToNestedHash::ClassMethods
    end

  private

    module ToNestedHash
      def to_nested_hash(*)
        self.class.nested_hash_representer.new(self).to_hash
      end

      module ClassMethods
        # Create a hash representer on-the-fly to serialize the form to a hash.
        def nested_hash_representer
          @nested_hash_representer ||= Class.new(representer_class) do
            include Representable::Hash

            representable_attrs.each do |dfn|
              dfn.merge!(readable: true) # the nested hash contains all fields.
              dfn.merge!(as: dfn[:private_name]) # nested hash keys by model property names.

              dfn.merge!(
                prepare:       lambda { |model, *| model }, # TODO: why do we need that here?
                serialize:     lambda { |form, args| form.to_nested_hash },
              ) if dfn[:twin]

              self
            end
          end
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


    # Excludes :virtual and :writeable: false properties from #sync in this twin.
    module Writeable
      def sync_options(options)
        options = super

        protected_fields = schema.each.find_all { |d| d[:writeable] == false }.collect { |d| d.name }
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
        scalars   = schema.each(scalar: true).collect { |dfn| dfn.name }
        unchanged = scalars - changed.keys

        # exclude unchanged scalars, nested forms and changed scalars still go in here!
        options.exclude!(unchanged)
        super
      end
    end
  end
end
