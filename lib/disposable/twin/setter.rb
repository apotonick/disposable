module Disposable::Twin::Setter
  module ClassMethods
    def property(name, options={}, &block)
      super(name, options, &block).tap do
        create_setter!(name, options[:setter])  # define coercing setter after twin.
      end
    end

    def create_setter!(name, setter)
      mod = Module.new do
        define_method("#{name}=") do |value|
          super Uber::Options::Value.new(setter).evaluate(self, value)
        end
      end
      include mod
    end
  end

  def self.included(includer)
    includer.extend ClassMethods
  end
end
