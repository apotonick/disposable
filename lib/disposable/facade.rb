require "delegate"

module Disposable
  class Facade < SimpleDelegator
    module Facadable
      def facade
        # TODO: check if already facaded.
        self.class.facade_class.new(self)
      end
    end

    def self.facades(klass)
      facade_class = self

      klass.instance_eval do
        include Facadable
        @_facade_class = facade_class

        def facade_class
          @_facade_class
        end
      end # TODO: use hooks.
    end
  end
end