require "delegate"
require "uber/inheritable_attr"

module Disposable
  class Facade < SimpleDelegator
    extend Uber::InheritableAttr
    inheritable_attr :facade_options
    self.facade_options = [nil, {}]


    module Facadable
      # used in facaded.
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
        facade_options = [klass, options] # TODO: test.

        self.facade_options = facade_options

        facade_class = self
        klass.instance_eval do
          include Facadable
          @_facade_class = facade_class

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


    # Extend your facade and call Song.build, includes ClassMethods (extend constructor).
    module Subclass
      def build(*args)
        facade_class = self
        Class.new(facade_options.first).class_eval do
          include facade_class::InstanceMethods # TODO: check if exists.
          extend facade_class::ClassMethods # TODO: check if exists.

          self
        end.new(*args)
      end

      alias_method :subclass, :build
    end


    module Refine
      def initialize(facaded) # DISCUSS: should we override ::facade here?
        super.tap do |res|
          refine(facaded)
        end
      end

      def refine(facaded)
        facaded.extend(self.class::Refinements)
      end
    end
  end
end