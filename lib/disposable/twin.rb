require 'uber/inheritable_attr'
require 'representable/decorator'
require 'representable/hash'

module Disposable
  class Twin
    class Decorator < Representable::Decorator
      include Representable::Hash

      # DISCUSS: same in reform, is that a bug in represntable?
      def self.clone # called in inheritable_attr :representer_class.
        Class.new(self) # By subclassing, representable_attrs.clone is called.
      end
    end

    extend Uber::InheritableAttr
    inheritable_attr :representer_class
    self.representer_class = Class.new(Decorator)

    inheritable_attr :_model

    def self.model(name)
      self._model = name
    end


    def self.property(name, *args, &block)
      attr_accessor name

      representer_class.property(name, *args, &block)
    end


    def self.from(model) # TODO: private.
      new(model)
    end

    def self.new(model=nil)
      model, options = nil, model if model.is_a?(Hash) # sorry but i wanna have the same API as ActiveRecord here.
      super(model || _model.new, *[options].compact) # TODO: make this nicer.
    end

    def self.find(id)
      new(_model.find(id))
    end

    def save # use that in Reform::AR.
      sync_attrs    = self.class.representer_class.new(self).to_hash
      update_attrs  = sync_attrs.reject { |k| ["album"].include?(k) }
      save_attrs    = sync_attrs.select { |k| ["album"].include?(k) }

      model.update_attributes(update_attrs)

      save_attrs.values.map(&:save)

      # FIXME: sync again, here, or just id?
      self.id = model.id
    end

    # below is the code for a representable-style twin:

    # TODO: improve speed when setting up a twin.
    def initialize(model, options={})
      @model = model

      # FIXME: make that in representable:
      options = options.tap do |h|
  h.keys.each { |k| h[k.to_s] = h.delete(k) }
end

      # DISCUSS: does the case exist where we get model AND options? if yes, test. if no, we can save the mapping and just use options.
      from_hash(self.class.representer_class.new(model).to_hash.
        merge(options))
    end

  private
    def from_hash(options={})
      self.class.representer_class.new(self).from_hash(options)
    end

    attr_reader :model # TODO: test
  end
end