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
    end

    class Definition < Representable::Definition
      def dynamic_options
        super + [:twin]
      end
    end
  end
end