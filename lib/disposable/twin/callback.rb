# Callback is designed to work with twins under the hood since twins track events
# like "adding" or "deleted". However, it could run with other model layers, too.
# For example, when you manage to make ActiveRecord track those events, you won't need a
# twin layer underneath.
module Disposable::Twin::Callback
  class Group
    # TODO: make this easier via declarable.
    extend Uber::InheritableAttr
    inheritable_attr :representer_class
    self.representer_class = Class.new(Representable::Decorator) do
      def self.default_inline_class
        Group
      end
    end

    def self.feature(*args)
    end

    def self.property(*args, &block)
      representer_class.property(*args, &block)
    end

    def self.collection(*args, &block)
      representer_class.collection(*args, &block)
    end


    def initialize(twin)
      @twin = twin
    end

    inheritable_attr :hooks
    self.hooks = []

    class << self
      %w(on_add on_delete on_destroy on_update on_create on_change).each do |event|
        define_method event do |*args|
          hooks << [event.to_sym, args]
        end
      end
    end


    def call(options={})
      self.class.hooks.each do |cfg|
        event, args = cfg
        method      = args.first
        context     = self

        puts event
        # TODO: Use Option::Value here.
        Disposable::Twin::Callback::Dispatch.new(@twin).send( event) { |twin| context.send(method, twin) }
      end

      self.class.representer_class.representable_attrs.each do |definition|
        twin = @twin.send(definition.getter)

        # TODO: for scalar properties!

        # Group.new(twin).()
        definition.representer_module.new(twin).()
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