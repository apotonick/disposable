require "uber/inheritable_attr"

require "disposable/twin/representer"
require "disposable/twin/collection"
require "disposable/twin/setup"
require "disposable/twin/sync"
require "disposable/twin/save"
require "disposable/twin/option"
require "disposable/twin/builder"
require "disposable/twin/changed"

# Twin.new(model/composition hash/hash, options)
#   assign hash to @fields
#   write: write to @fields
#   sync/save is the only way to write back to the model.

module Disposable
  class Twin
    extend Uber::InheritableAttr

    inheritable_attr :twin_representer_class
    self.twin_representer_class = Class.new(Decorator)


    extend Representable::Feature # imports ::feature, which calls ::register_feature.
    def self.register_feature(mod)
      twin_representer_class.representable_attrs[:features][mod] = true
    end


    # TODO: move to Declarative, as in Representable and Reform.
    def self.property(name, options={}, &block)
      options[:private_name] = options.delete(:from) || name
      options[:pass_options] = true

      # FIXME: use only one representer. and make object_representer the authorative one, we really need the hash one only once.
      twin_representer_class.property(name, options, &block).tap do |definition|
        mod = Module.new do
          define_method(name)       { @fields[name.to_s] }
          # define_method(name)       { read_property(name) }
          define_method("#{name}=") { |value| write_property(name, value, definition) } # TODO: this is more like prototyping.
        end
        include mod

        # property -> build_inline(representable_attrs.features)
        # TODO: temporary hack to make definition not look typed. maybe we should make :twin copy of :extend and then get everything accepting :extend?
        if definition[:extend]
          nested_twin = definition[:extend].evaluate(nil)
          process_inline!(nested_twin, definition)
          # DISCUSS: could we use build_inline's api here to inject the name feature?

          definition.merge!(:twin => nested_twin)
          # definition.delete!(:extend)
        end
      end
    end

    def self.collection(name, options={}, &block)
      property(name, options.merge(collection: true), &block)
    end

    #
    def self.bla
      @bla ||= twin_representer_class.representable_attrs[:definitions]
    end

    include Setup

    module Accessors
    private
      def read_property(name, private_name)
        @fields[name.to_s]
      end

      # assumption: collections are always initialized from Setup since we assume an empty [] for "nil"/uninitialized collections.
      def write_property(name, value, dfn)
        return if dfn[:twin] and value.nil? # TODO: test me (model.composer => nil)
        value = dfn.array? ? wrap_collection(dfn, value) : wrap_scalar(dfn, value) if dfn[:twin]

        @fields[name.to_s] = value
      end

      def wrap_scalar(dfn, value)
        Twinner.new(dfn).(value)
      end

      def wrap_collection(dfn, value)
        Collection.for_models(Twinner.new(dfn), value)
      end
    end
    include Accessors

    # DISCUSS: this method might disappear or change pretty soon.
    def self.process_inline!(mod, definition)
    end

    # FIXME: this is experimental.
    module ToS
      def to_s
        return super if self.class.name
        "#<Twin (inline):#{object_id}>"
      end
    end
    include ToS


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
  end
end