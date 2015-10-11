# DISCUSS: sync via @fields, not reader? allows overriding a la reform 1.

require "uber/inheritable_attr"

require "disposable/twin/representer"
require "disposable/twin/collection"
require "disposable/twin/setup"
require "disposable/twin/sync"
require "disposable/twin/save"
require "disposable/twin/option"
require "disposable/twin/builder"
require "disposable/twin/changed"
require "disposable/twin/property_processor"
require "disposable/twin/persisted"
require "disposable/twin/default"

# Twin.new(model/composition hash/hash, options)
#   assign hash to @fields
#   write: write to @fields
#   sync/save is the only way to write back to the model.

module Disposable
  class Twin
    extend Uber::InheritableAttr

    inheritable_attr :representer_class
    self.representer_class = Class.new(Decorator)

    # Returns an each'able array of all properties defined in this twin.
    # Allows to filter using
    #   * collection: true
    #   * twin:       true
    #   * scalar:     true
    #   * exclude:    ["title", "email"]
    def schema
      self.class.representer_class
    end


    extend Representable::Feature # imports ::feature, which calls ::register_feature.
    def self.register_feature(mod)
      representer_class.representable_attrs[:features][mod] = true
    end


    class << self
      # TODO: move to Declarative, as in Representable and Reform.
      def property(name, options={}, &block)
        options[:private_name] = options.delete(:from) || name

        if options.delete(:virtual)
          options[:writeable] = options[:readable] = false
        end

        options[:extend] = options[:twin] # e.g. property :album, twin: Album.

        representer_class.property(name, options, &block).tap do |definition|
          create_accessors(name, definition)

          if definition[:extend] and !options[:twin]
            # This will soon be replaced with Declarative's API. # DISCUSS: could we use build_inline's api here to inject the name feature?
            nested_twin = definition[:extend].evaluate(nil)
            process_inline!(nested_twin, definition)

            definition.merge!(twin: nested_twin) # DISCUSS: where do we need this?
          end
        end
      end

      def collection(name, options={}, &block)
        property(name, options.merge(collection: true), &block)
      end

      def from_collection(collection)
        collection.collect { |model| new(model) }
      end

    private
      def create_accessors(name, definition)
        mod = Module.new do
          define_method(name)       { @fields[name.to_s] }
          # define_method(name)       { read_property(name) }
          define_method("#{name}=") { |value| write_property(name, value, definition) } # TODO: this is more like prototyping.
        end
        include mod
      end

      # DISCUSS: this method might disappear or change pretty soon.
      def process_inline!(mod, definition)
      end
    end

    include Setup


    module Accessors
    private
      # assumption: collections are always initialized from Setup since we assume an empty [] for "nil"/uninitialized collections.
      def write_property(name, value, dfn)
        if dfn[:twin] and value
          value = dfn.array? ? wrap_collection(dfn, value) : wrap_scalar(dfn, value)
        end

        field_write(name, value)
      end

      # Write the property's value without using the public writer.
      def field_write(name, value)
        @fields[name.to_s] = value
      end

      # Read the property's value without using the public reader.
      def field_read(name)
        @fields[name.to_s]
      end

      def wrap_scalar(dfn, value)
        Twinner.new(dfn).(value)
      end

      def wrap_collection(dfn, value)
        Collection.for_models(Twinner.new(dfn), value)
      end
    end
    include Accessors


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


  private
    module ModelReaders
      attr_reader :model # #model is a private concept.
      attr_reader :mapper
    end
    include ModelReaders

    include Option
  end
end