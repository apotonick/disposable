require "representable/decorator"
# require "representable/hash"

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
        Twin
      end


      class Options < ::Hash
        def exclude!(names)
          excludes.push(*names)
          self
        end

        def excludes
          self[:exclude] ||= []
        end
      end
    end # Decorator.
  end
end