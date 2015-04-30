module Disposable
  class Twin
    # Transforms incoming model properties. :twin properties will be twinned in #initialize.
    # Twin collections will be wrapped with Twin::Collection for public API.
    module Setup
    private
      def setup_representer
        # simply pass through all properties from the model to the respective twin reader method.
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