require "representable/decorator"
require "representable/hash"

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

      def self.each(options={})
        return representable_attrs[:definitions].values unless block_given?

        definitions = representable_attrs

        definitions.each do |dfn|
          next if options[:exclude]    and options[:exclude].include?(dfn.name)
          next if options[:scalar]     and dfn[:collection]
          next if options[:collection] and ! dfn[:collection]
          next if options[:twin]       and ! dfn[:twin]

          yield dfn
        end

        definitions
      end

      def self.default_inline_class
        Disposable::Twin
      end


      # TODO: check how to simplify.
      class Options < ::Hash
        def exclude!(names)
          excludes.push(*names) #if names.size > 0
          self
        end

        def excludes
          self[:exclude] ||= []
        end
      end
    end

  end
end