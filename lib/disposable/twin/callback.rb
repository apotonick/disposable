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
      @invocations = []
    end

    attr_reader :invocations

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

        res = callback!(event, args)

        invocations << res
      end

      self.class.representer_class.representable_attrs.each do |definition|
        twin = @twin.send(definition.getter) # album.songs

        # TODO: what if collection must be run before on_update ?
        # TODO: for scalar properties!

        # Group.new(twin).()
        @invocations += definition.representer_module.new(twin).().invocations
      end

      self
    end

  private
    # Runs one callback.
    def callback!(event, args)
      method      = args.first
      context     = self

      # TODO: Use Option::Value here.
      Disposable::Twin::Callback::Dispatch.new(@twin).(event, method) { |twin| context.send(method, twin) }
    end
  end

  # Invokes callback for one event, e.g. on_add(:relax!).
  class Dispatch
    def initialize(twins)
      @twins = twins.is_a?(Array) ? twins : [twins] # TODO: find that out with Collection.
      @invocations = []
    end

    def call(event, method, *args, &block) # FIXME: as long as we only support method, pass in here.
      send(event, *args, &block)
      puts "Dispatch result: #{@invocations.inspect}"
      [event, method, @invocations]
    end

    def on_add(state=nil, &block) # how to call it once, for "all"?
      # @twins can only be Collection instance.
      @twins.added.each do |item|
        run!(item, &block) if state.nil?
        run!(item, &block) if item.created? && state == :created # :created # DISCUSS: should we really keep that?
      end
    end

    def on_delete(&block)
      # @twins can only be Collection instance.
      @twins.deleted.each do |item|
        run!(item, &block)
      end
    end

    def on_destroy(&block)
      @twins.destroyed.each do |item|
        run!(item, &block)
      end
    end

    def on_update(&block)
      @twins.each do |twin|
        next if twin.created?
        next unless twin.persisted? # only persisted can be updated.
        next unless twin.changed?
        run!(twin, &block)
      end
    end

    def on_create(&block)
      @twins.each do |twin|
        next unless twin.created?
        run!(twin, &block)
      end
    end

    def on_change(name=nil, &block)
      @twins.each do |twin|
        if name
          run!(twin, &block) if twin.changed?(name)
          next
        end

        next unless twin.changed?
        run!(twin, &block)
      end
    end

  private
    def run!(twin, &block)
      yield(twin).tap do |res|
        @invocations << twin
      end
    end
  end
end