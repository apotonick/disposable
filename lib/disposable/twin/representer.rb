module Disposable
  class Twin
    class Decorator < Representable::Decorator
      include Representable::Hash
      include AllowSymbols

      # DISCUSS: same in reform, is that a bug in represntable?
      def self.clone # called in inheritable_attr :representer_class.
        Class.new(self) # By subclassing, representable_attrs.clone is called.
      end

      def self.build_config
        Config.new(Definition)
      end

      def twin_names
        representable_attrs.
          find_all { |attr| attr[:twin] }.
          collect { |attr| attr.name.to_sym }
      end




       # Returns hash of all property names.
      def self.fields(&block)
        representable_attrs.find_all(&block).map(&:name)
      end

      def self.each(only_form=true, &block)
        definitions = representable_attrs
        definitions = representable_attrs.find_all { |attr| attr[:form] } if only_form

        definitions.each(&block)
        self
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

        only_forms = options[:all] ? false : true
        base       = options[:superclass] || representer_class

        representers[name] = Class.new(base).each(only_forms, &block) # let user modify representer.
      end
    end

    class Definition < Representable::Definition
      def dynamic_options
        super + [:twin]
      end
    end
  end
end