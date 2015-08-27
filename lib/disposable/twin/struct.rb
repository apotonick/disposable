  module Disposable
  class Twin
    # Twin that uses a hash to populate.
    #
    #   Twin.new(id: 1)
    module Struct
      def read_value_for(dfn, options)
        name = dfn.name
        @model[name.to_s] || @model[name.to_sym] # TODO: test sym vs. str.
      end

      def sync_hash_representer # TODO: make this without representable, please.
        Sync.hash_representer(self.class) do |dfn|
          dfn.merge!(
            prepare:       lambda { |model, *| model },
            serialize: lambda { |model, *| model.sync! },
            representable: true
          ) if dfn[:twin]
        end
      end

      def sync(options={})
        sync_hash_representer.new(self).to_hash
      end
      alias_method :sync!, :sync
    end
  end
end