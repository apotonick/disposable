  module Disposable
  class Twin
    # Twin that uses a hash to populate.
    #
    #   Twin.new(id: 1)
    module Struct
      def setup_properties!(options={})
        hash_representer.new(self).from_hash(@model.merge(options))
      end

      def hash_representer
        Class.new(schema) do
          include Representable::Hash
          include Representable::Hash::AllowSymbols

          representable_attrs.each do |dfn|
            dfn.merge!(
              prepare:       lambda { |model, *| model },
              instance:      lambda { |model, *| model }, # FIXME: this is because Representable thinks this is typed? in Deserializer.
              representable: false,
            ) if dfn[:twin]
          end
        end
      end

      def sync_hash_representer
        hash_representer.clone.tap do |rpr|
          rpr.representable_attrs.each do |dfn|
            dfn.merge!(
              serialize: lambda { |model, *| model.sync! },
              representable: true
            ) if dfn[:twin]
          end
        end
      end

      def sync(options={})
        sync_hash_representer.new(self).to_hash
      end
      alias_method :sync!, :sync
    end
  end
end