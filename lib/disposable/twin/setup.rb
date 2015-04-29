module Disposable
  class Twin
    module Setup
    private
      def setup_representer
        self.class.representer(:setup, :superclass => self.class.object_representer_class) do |dfn| # only nested twins.
          dfn.merge!(
            :representable => false, # don't call #to_hash, only prepare.
            #:class => Module,
            :instance       => lambda { |model, index, args| args.binding[:twin].evaluate(nil).new(model) } # wrap nested properties in twin.

          )
        end
      end

      require "representable/debug"
      def initialize(model, *args)
        super
        setup_representer.new(self).extend(Representable::Debug).from_object(model)
      end
    end
  end
end