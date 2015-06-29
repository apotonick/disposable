require "virtus"

# confession: i love virtus' coercion.
module Disposable::Twin::Coercion
  module ClassMethods
    def property(name, options={}, &block)
      super(name, options, &block).tap do
        coercing_setter!(name, options[:type])  # define coercing setter after twin.
      end
    end

    def coercing_setter!(name, type)
      mod = Module.new do
        define_method("#{name}=") { |value| super Virtus::Attribute.build(type).coerce(value) }
      end
      include mod
    end
  end

  def self.included(includer)
    includer.extend ClassMethods
  end
end
