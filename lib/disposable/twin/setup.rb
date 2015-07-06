module Disposable
  class Twin
    # Read all properties at twin initialization time from model.
    # Simply pass through all properties from the model to the respective twin writer method.
    # This will result in all twin properties/collection items being twinned, and collections
    # being Collection to expose the desired public API.
    module Setup
      # test is in incoming hash? is nil on incoming model?

      def initialize(model, options={})
        @fields = {}
        @model  = model
        @mapper = mapper_for(model) # mapper for model.

        setup_properties!(model, options)
      end

    private
      def mapper_for(model)
        model
      end

      def setup_properties!(model, options)
        schema.each do |dfn|
          next if dfn[:readable] == false

          value = setup_value_for(dfn, options)

          setup_write!(dfn, value)
        end

        merge_options!(options) # FIXME: call writer!!!!!!!!!!
        # from_hash(options) # assigns known properties from options.
      end

      def setup_value_for(dfn, options)
        name  = dfn.name
        options[name.to_sym] || mapper.send(name) # model.title.
      end

      def setup_write!(dfn, value)
        send(dfn.setter, value)
      end

      def merge_options!(options)
        # TODO: ask charliesome if that is faster with return unless options.size.
        options.each { |k, v| @fields[k.to_s] = v } # TODO: this merges every option, not only defined ones.
      end


      # Including this will _not_ use the property's setter in Setup and allow you to override it.
      module SkipSetter
        def setup_write!(dfn, value)
          write_property(dfn.name, value, dfn)
        end
      end
    end # Setup
  end
end