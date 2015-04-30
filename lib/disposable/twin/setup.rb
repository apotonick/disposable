module Disposable
  class Twin
    # Transforms incoming model properties. :twin properties will be twinned in #initialize.
    # Twin collections will be wrapped with Twin::Collection for public API.
    module Setup
    private
      def setup_representer
        self.class.representer(:setup, :superclass => self.class.object_representer_class) do |dfn| # only nested twins.
          dfn.merge!(
            :representable => false, # don't call #from_object, only :instance.
            # FIXME: this should not apply to properties!
            :parse_filter  => lambda { |collection, *args| Twin::Collection.new(dfn[:twin], collection) }, # TODO: make this configurable in representable!
            :instance      => lambda { |model, *args| args.last.binding[:twin].evaluate(nil).new(model) } # wrap nested properties in twin.
            # FIXME: THAT SIGNATURE SUCKS: |model, index, args| (for collections), why can't it be model, args with args.index ?
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