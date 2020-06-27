gem 'dry-types', '~> 1.0'
require "dry-types"

module Disposable::Twin::Coercion
  module Types
    include Dry.Types()
  end

  module ClassMethods
    def property(name, options={}, &block)
      super(name, options, &block).tap do
        coercing_setter!(name, options[:type]) if options[:type]
      end
    end

    def coercing_setter!(name, type)
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
