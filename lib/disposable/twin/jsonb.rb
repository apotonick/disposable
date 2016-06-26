require "disposable/twin/struct"

class Disposable::Twin
  module JSONB
    def self.included(includer)
      # jsonb: true top-level properties need :default support.
      includer.feature Default

      # Recursively include Struct in :jsonb and nested properties.
      # defaults is applied to all ::property calls.
      includer.defaults do |name, options|
        if options[:jsonb] # only apply to `jsonb: true`.
          jsonb_options
        else
          {}
        end
      end
    end

  private
    # Note that :_features `include`s modules in this order, first to last.
    def self.jsonb_options
      { _features: [NestedDefaults, Struct, JSONB::Sync], default: ->(*) { Hash.new } }
    end

    # NestedDefaults for properties nested in the top :jsonb column.
    module NestedDefaults
      def self.included(includer)
        includer.defaults do |name, options|
          if options[:_nested_builder] # DISCUSS: any other way to figure out we're nested?
            JSONB.jsonb_options
          else
            { }
          end
        end
      end
    end

    module Sync
      def sync!(options={})
        @model.merge(super)
      end
    end
  end
end
