require "representable/decorator"
require "representable/hash"
require "representable/hash/allow_symbols"

module Disposable
  class Twin
    class Decorator < Representable::Decorator
      # Overrides representable's Definition class so we can add semantics in our representers.
      class Definition < Representable::Definition
        def dynamic_options
          super + [:twin]
        end

        def twin_class
          self[:twin].evaluate(nil) # FIXME: do we support the :twin option, and should it be wrapped?
        end
      end


      # DISCUSS: same in reform, is that a bug in represntable?
      def self.clone # called in inheritable_attr :representer_class.
        Class.new(self) # By subclassing, representable_attrs.clone is called.
      end

      # FIXME: this is not properly used when inheriting - fix that in representable.
      def self.build_config
        Config.new(Definition)
      end

      def self.each(only_nested=true, &block)
        definitions = representable_attrs
        definitions = representable_attrs.find_all { |attr| attr[:twin] } if only_nested

        definitions.each(&block)
        self
      end

      def self.default_inline_class
        Disposable::Twin
      end


      # this decorator allows hash transformations (to and from, e.g. for nested_hash).
      class Hash < self
        include Representable::Hash
        include AllowSymbols

        # FIXME: this sucks. fix in representable.
        def self.build_config
          Config.new(Definition)
        end
      end

      require "representable/object"
      class Object < self
        include Representable::Object

        # FIXME: this sucks. fix in representable.
        def self.build_config
          Config.new(Definition)
        end

        # Generate Twin classes for us when using inline ::property or ::collection.
        def self.default_inline_class # FIXME: do we need this?
          Disposable::Twin
        end
      end


      # TODO: check how to simplify.
      class Options < ::Hash
        def include!(names)
          includes.push(*names) #if names.size > 0
          self
        end

        def exclude!(names)
          excludes.push(*names) #if names.size > 0
          self
        end

        def excludes
          self[:exclude] ||= []
        end

        def includes
          self[:include] ||= []
        end
      end
    end


    # Introduces ::representer to generate/cache transformer representers.
    module Representer
      def representers # keeps all transformation representers for one class.
        @representers ||= {}
      end

      def representer(name=nil, options={}, &block)
        return representer_class.each(&block) if name == nil
        return representers[name] if representers[name] # don't run block as this representer is already setup for this form class.

        only_nested = options[:all] ? false : true
        base       = options[:superclass] || representer_class

        representers[name] = Class.new(base).each(only_nested, &block) # let user modify representer.
      end
    end
  end
end