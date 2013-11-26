require "delegate"

module Disposable
  class Facade < SimpleDelegator
    module Facadable
      def facade
        options = self.class.facade_options

        if options.last[:if]
          return self unless options.last[:if].call(self)
        end

        # TODO: check if already facaded.
        # TODO: allow different facades.
        facade!
      end

      def facade!
        #self.extend(Id)
        self.class.facade_options.first.new(self)
      end
    end

    def self.facades(klass, options={})
      facade_class = self

      klass.instance_eval do
        include Facadable
        @_facade_options = [facade_class, options]

        def facade_options
          @_facade_options
        end
      end # TODO: use hooks.
    end


    # Forward #id to facaded. this is only a concern in 1.8.
    def id
      __getobj__.id
    end


    alias_method :facaded, :__getobj__
  end
end