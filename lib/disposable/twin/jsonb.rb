require "disposable/twin/struct"

class Disposable::Twin
  module JSONB
    def self.included(includer)
      # jsonb: true top-level properties need :default support.
      includer.include Default

      # Recursively include Struct in :jsonb and nested properties.
      # defaults is applied to all ::property calls.
      includer.defaults do |name, options|
        puts "@@@@@ #{options.inspect}"
        if options[:jsonb] # only apply to `jsonb: true`.
          jsonb_options
        else
          {}
        end
      end
    end

  private
    def self.jsonb_options
      { _features: [Default, Struct, NestedDefaults], default: ->(*) { Hash.new } }
    end

    # NestedDefaults for properties nested in the top :jsonb column.
    module NestedDefaults
      def self.included(includer)
        includer.defaults do |name, options|
          if options[:_nested_builder]
            JSONB.jsonb_options
          else
            { }
          end
        end
      end
    end
  end
end
