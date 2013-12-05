require "delegate"
require "hooks/inheritable_attribute"

module Disposable
  class Facade < SimpleDelegator
    extend Hooks::InheritableAttribute
    inheritable_attr :facade_options
    self.facade_options = [nil, {}]


    module Facadable
      def facade!(facade_class=nil)
        facade_class ||= self.class.facade_class
        facade_class.facade!(self)
      end

      def facade(facade_class=nil)
        facade_class ||= self.class.facade_class
        facade_class.facade(self)
      end
    end


    class << self
      def facades(klass, options={})
        facade_options = [self, options]

        self.facade_options = facade_options

        klass.instance_eval do
          include Facadable
          @_facade_class = facade_options.first

          def facade_class
            @_facade_class
          end
        end # TODO: use hooks.
      end

      # TODO: move both into Facader instance.
      def facade(facaded)
        if facade_options.last[:if]
          return facaded unless facade_options.last[:if].call(facaded)
        end

        # TODO: check if already facaded.
        facade!(facaded)
      end

      def facade!(facaded)
        new(facaded)
      end
    end

    # Forward #id to facaded. this is only a concern in 1.8.
    def id
      __getobj__.id
    end


    alias_method :facaded, :__getobj__
  end
end