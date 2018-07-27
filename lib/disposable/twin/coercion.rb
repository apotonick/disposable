require "dry-types"

module Disposable::Twin::Coercion
  module Types
    include Dry::Types.module
  end

  DRY_TYPES_VERSION = Gem::Version.new(Dry::Types::VERSION)
  DRY_TYPES_CONSTANT = DRY_TYPES_VERSION < Gem::Version.new("0.13.0") ? Types::Form : Types::Params

  module ClassMethods
    def property(name, options={}, &block)
      super(name, options, &block).tap do
        coercing_setter!(name, options[:type], options[:nilify]) if options[:type] || options[:nilify]
      end
    end

    def coercing_setter!(name, type, nilify=false)
     type = type ? (DRY_TYPES_CONSTANT::Nil | type) : DRY_TYPES_CONSTANT::Nil if nilify

      mod = Module.new do
        define_method("#{name}=") do |value|
          super type.(value)
        end
      end
      include mod
    end
  end

  def self.included(includer)
    includer.extend ClassMethods
  end
end
