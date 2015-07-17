require "disposable/expose"
require "disposable/composition"

module Disposable
  class Twin
    module Expose
      module ClassMethods
        def expose_class
          @expose_class ||= Class.new(Disposable::Expose).from(representer_class)
        end
      end # ClassMethods.

      def self.included(base)
        base.extend(ClassMethods)
      end

      module Initialize
        def mapper_for(*args)
          self.class.expose_class.new(*args)
        end
      end
      include Initialize
    end


    module Composition
      module ClassMethods
        def expose_class
          @expose_class ||= Class.new(Disposable::Composition).from(representer_class)
        end

        def on(model_key, &block)
          builder = OnBuilder.new(model_key, self)
          builder.instance_eval(&block)
        end

        class OnBuilder
          def initialize(model_key, definition)
            @model_key = model_key
            @definition = definition
          end

          def property(name, options={}, &block)
            @definition.property(name, options.merge(on: @model_key), &block)
          end
        end
      end

      def self.included(base)
        base.send(:include, Expose::Initialize)
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

    private
      def save_model
        res = true
        mapper.each { |twin| res &= twin.save } # goes through all models in Composition.
        res
      end
    end
  end
end
