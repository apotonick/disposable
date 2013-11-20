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
  end
end