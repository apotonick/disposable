require "dry-types"

module Disposable::Twin::Coercion
  module Types
    include Dry::Types.module
  end

  module ClassMethods
    def property(name, options={}, &block)
      super(name, options, &block).tap do
        coercing_setter!(name, options[:type], options[:nilify]) if options[:type] || options[:nilify]
      end
    end

    def coercing_setter!(name, type, nilify=false)
     type = type ? (Types::Form::Nil | type) : Types::Form::Nil if nilify

      mod = Module.new do
        define_method("#{name}=") do |value|
          super type.call(value)
        end
      end
      include mod
    end
  end

  def self.included(includer)
    includer.extend ClassMethods
  end
end
