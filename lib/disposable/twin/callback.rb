# Callback is designed to work with twins under the hood since twins track events
# like "adding" or "deleted". However, it could run with other model layers, too.
# For example, when you manage to make ActiveRecord track those events, you won't need a
# twin layer underneath.
require "hooks"

module Disposable::Twin::Callback
  class Group < Representable::Decorator

    include Hooks
    define_hook :on_add
    define_hook :on_change
    define_hook :on_create
    define_hook :on_update

    def self.default_inline_class
      Group
    end

    def call(options={})
      # FIXME: this is not in the order it was added.

      # puts "@@@@@ #{represented.inspect}"
      Disposable::Twin::Callback::Dispatch.new(represented).on_change{ |twin| run_hook :on_change, self }
      Disposable::Twin::Callback::Dispatch.new(represented).on_create{ |twin| run_hook :on_create, self }
      Disposable::Twin::Callback::Dispatch.new(represented).on_update{ |twin| run_hook :on_update, self }

      representable_attrs.each do |definition|
        twin = represented.send(definition.getter)

        if definition.array?
          Disposable::Twin::Callback::Dispatch.new(twin).on_add{ |twin| run_hook :on_add, twin }
          Disposable::Twin::Callback::Dispatch.new(twin).on_delete{ |twin| run_hook :on_delete, self }
        end

        # TODO: for scalar properties!

        Group.new(twin).()
      end
    end
  end

  class Dispatch
    def initialize(twins)
      @twins = twins.is_a?(Array) ? twins : [twins] # TODO: find that out with Collection.
    end

    def on_add(state=nil) # how to call it once, for "all"?
      # @twins can only be Collection instance.
      @twins.added.each do |item|
        yield item if state.nil?
        yield item if item.created? && state == :created # :created # DISCUSS: should we really keep that?
      end
    end

    def on_delete
      # @twins can only be Collection instance.
      @twins.deleted.each do |item|
        yield item
      end
    end

    def on_destroy
      @twins.destroyed.each do |item|
        yield item
      end
    end

    def on_update
      @twins.each do |twin|
        next if twin.created?
        next unless twin.persisted? # only persisted can be updated.
        next unless twin.changed?
        yield twin
      end
    end

    def on_create
      @twins.each do |twin|
        next unless twin.created?
        yield twin
      end
    end

    def on_change(name=nil)
      @twins.each do |twin|
        if name
          yield twin if twin.changed?(name)
          next
        end

        next unless twin.changed?
        yield twin
      end
    end
  end
end