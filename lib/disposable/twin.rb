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


    def self.from(model)
      new(model)
    end

    def self.new(model=nil)
      super(model || _model.new)
    end

    def self.find(id)
      from(_model.find(id))
    end

    # below is the code for a representable-style twin:

    # TODO: improve speed when setting up a twin.
    def initialize(model)
      @model = model

      from_hash(self.class.representer_class.new(model).to_hash)
    end

    def from_hash(options={})
      self.class.representer_class.new(self).from_hash(options)
    end

  private
    attr_reader :model # TODO: test
  end
end