module Disposable
  class Twin
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
        setup_representer.new(self).from_object(model) # this reads from model, transforms, and writes to self.
      end
    end
  end
end