require "uber/inheritable_attr"

require "disposable/twin/representer"
require "disposable/twin/collection"
require "disposable/twin/setup"
require "disposable/twin/sync"
require "disposable/twin/option"
require "disposable/twin/builder"

# Twin.new(model/composition hash/hash, options)
#   assign hash to @fields
#   write: write to @fields
#   sync/save is the only way to write back to the model.

# TODO: allow setting external deserialization representer, e.g. JSON::HAL or JSONAPI.

module Disposable
  class Twin
    extend Representer # include ::representer for transformator caching.

    extend Uber::InheritableAttr
    inheritable_attr :representer_class
    self.representer_class = Class.new(Decorator::Hash)

    # DISCUSS: since i started playing with Representable::Object, which is way faster than
    # going the Hash way, i use two schema representers here. they are identical except for
    # the engine.
    # it would be cool to have only one, one day.
    inheritable_attr :object_representer_class
    self.object_representer_class = Class.new(Decorator::Object)

    inheritable_attr :twin_representer_class
    self.twin_representer_class = Class.new(Decorator)


    extend Representable::Feature # imports ::feature, which calls ::register_feature.
    def self.register_feature(mod)
      twin_representer_class.representable_attrs[:features][mod] = true
    end


    # TODO: move to Declarative, as in Representable and Reform.
    def self.property(name, options={}, &block)
      deprecate_as!(options) # TODO: remove me in 0.1.0
      options[:private_name] = options.delete(:from) || name
      options[:pass_options] = true


      # TODO: this should be more modular.
      options[:_readable]  = options.delete(:readable)
      options[:_writeable] = options.delete(:writeable)



      # hash_representer_class and object_representer_class are only a 1-level representation of the structure.
      representer_class.property(name, options).tap do |definition|
        definition.merge!(twin:true) if block
      end

      object_representer_class.property(name, options).tap do |definition|
        definition.merge!(twin:true) if block
      end

      # FIXME: use only one representer. and make object_representer the authorative one, we really need the hash one only once.
      twin_representer_class.property(name, options, &block).tap do |definition|
        mod = Module.new do
          define_method(name)       { read_property(name, options[:private_name]) }
          define_method("#{name}=") { |value| write_property(name, options[:private_name], value, definition) } # TODO: this is more like prototyping.
        end
        include mod

        # property -> build_inline(representable_attrs.features)
        # TODO: temporary hack to make definition not look typed. maybe we should make :twin copy of :extend and then get everything accepting :extend?
        if definition[:extend]
          nested_twin = definition[:extend].evaluate(nil)
          process_inline!(nested_twin, definition)
          # DISCUSS: could we use build_inline's api here to inject the name feature?

          definition.merge!(:twin => nested_twin)
          definition.delete!(:extend)
        end
      end
    end

    def self.collection(name, options={}, &block)
      property(name, options.merge(collection: true), &block)
    end


    module Initialize
      def initialize(model, options={})
        @fields = {}
        @model  = model

        from_hash(options) # assigns known properties from options.
      end
    end
    include Initialize


    # read/write to twin using twin's API (e.g. #record= not #album=).
    def self.write_representer
      representer = Class.new(representer_class) # inherit configuration
    end

  private
    def read_property(name, private_name)
      return @fields[name.to_s] if @fields.has_key?(name.to_s)

      # FIXME: is this used? Only when Setup is not included.
      @fields[name.to_s] = read_from_model(private_name)
    end

    def read_from_model(getter)
      model.send(getter)
    end

    # assumption: collections are always initialized from Setup since we assume an empty [] for "nil"/uninitialized collections.
    def write_property(name, private_name, value, dfn)
      value = dfn.array? ? wrap_collection(dfn, value) : wrap_scalar(dfn, value) if dfn[:twin]

      @fields[name.to_s] = value
    end

    def wrap_scalar(dfn, value)
      Twinner.new(dfn).(value)
    end

    def wrap_collection(dfn, value)
      Collection.for_models(Twinner.new(dfn), value)
    end

    # DISCUSS: this method might disappear or change pretty soon.
    def self.process_inline!(mod, definition)
    end

    def from_hash(options)
      self.class.write_representer.new(self).from_hash(options)
    end


    class Twinner
      def initialize(dfn)
        @dfn = dfn
      end

      def call(value)
        @dfn.twin_class.new(value)
      end
    end


    attr_reader :model # TODO: test

    include Option

    def self.deprecate_as!(options) # TODO: remove me in 0.1.0
      return unless as = options.delete(:as)
      options[:from] = as
      warn "[Disposable] The :as options got renamed to :from."
    end
  end
end