module Disposable
  class Twin
    # Read all properties at twin initialization time from model.
    # Simply pass through all properties from the model to the respective twin writer method.
    # This will result in all twin properties/collection items being twinned, and collections
    # being Collection to expose the desired public API.
    module Setup
    private
      def setup_representer
        self.class.representer(:setup, :superclass => self.class.object_representer_class) do |dfn| # only nested twins.
          dfn.merge!(
            :instance      => lambda { |fragment, *| fragment },
            :representable => false
          )
        end
      end

      def initialize(model, *args)
        super

        options = setup_options(Decorator::Options[]) # handles :_readable.

        setup_representer.new(self).from_object(model, options) # this reads from model and writes to self.
      end

      # FIXME: in Twin#read_property, this is used to "lazy-load". we don't want that in combo with Setup. Solution: make "lazy-loading" and exclusive second feature.
      def read_from_model(*)
      end


      module SetupOptions
        # Override to customize what gets copied to the twin.
        def setup_options(options)
          options
        end
      end
      include SetupOptions


      # TODO: cache if non-dynamic.
      # TODO: make dynamic.
      module Readable
        def setup_options(options)
          options = super

          empty_fields = self.class.object_representer_class.representable_attrs.find_all { |d| d[:_readable] == false }.collect { |d| d.name.to_sym }
          options.exclude!(empty_fields)
        end
      end
      include Readable

    end # Setup
  end
end