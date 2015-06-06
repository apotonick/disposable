module Disposable
  class Twin
    # Allows setting a twin class for a host object (e.g. a cell, a form, or a representer) using ::twin
    # and imports a method #build_twin to initialize this twin.
    #
    # Example:
    #
    #   class SongTwin < Disposable::Twin
    #     properties :id, :title
    #     option :is_released
    #   end
    #
    #   class Cell
    #     include Disposable::Twin::Builder
    #     twin SongTwin
    #
    #     def initialize(model, options)
    #       @twin = build_twin(model, options)
    #     end
    #   end
    #
    # An optional block passed to ::twin will be called per property yielding the Definition instance.
    module Builder
      def self.included(base)
        base.class_eval do
          extend Uber::InheritableAttr
          inheritable_attr :twin_class
          extend ClassMethods
        end
      end

      module ClassMethods
        def twin(twin_class, &block)
          twin_class.representer_class.representable_attrs.each { |dfn| yield(dfn) } if block_given?
          self.twin_class = twin_class
        end
      end

    private

      def build_twin(*args)
        self.class.twin_class.new(*args)
      end
    end
  end
end