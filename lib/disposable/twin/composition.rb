require "disposable/expose"
require "disposable/composition"

module Disposable
  class Twin
    module Expose
      module ClassMethods
        def expose_class
          @expose_class ||= Class.new(Disposable::Expose).from(representer_class)
        end
      end

      def self.included(base)
        base.extend(ClassMethods)
      end


      def initialize(*args)
        super self.class.expose_class.new(*args)
      end
    end


    module Composition
      module ClassMethods
        def expose_class
          @expose_class ||= Class.new(Disposable::Composition).from(representer_class)
        end
      end

      def self.included(base)
        base.send(:include, Disposable::Twin::Expose)
        base.extend(ClassMethods)
      end

      def to_nested_hash(*)
        hash = {}

        @model.each do |name, model| # TODO: provide list of composee attributes in Composition.
          part_properties = self.class.representer_class.representable_attrs.find_all { |dfn| dfn[:on] == name }.collect(&:name).collect(&:to_sym)
          hash[name] = self.class.nested_hash_representer.new(self).to_hash(include: part_properties)
        end

        hash
      end
    end
  end
end