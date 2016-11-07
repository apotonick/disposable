class Disposable::Twin
  module Property
    # Twin that uses a hash to populate.
    #
    #   Twin.new(id: 1)
    module Struct
      def read_value_for(dfn, options)
        name = dfn[:name]
        @model.key?(name.to_s) ? @model[name.to_s] : @model[name.to_sym]
      end

      def sync_hash_representer # TODO: make this without representable, please.
        Sync.hash_representer(self.class) do |dfn|
          dfn.merge!(
            prepare:       lambda { |options| options[:input] },
            serialize: lambda { |options| options[:input].sync! },
            representable: true
          ) if dfn[:nested]
        end
      end

      def sync(options={})
        sync_hash_representer.new(self).to_hash
      end
      alias_method :sync!, :sync

      # So far, hashes can't be persisted separately.
      def save!
      end
    end
  end # Property
end
