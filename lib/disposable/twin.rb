require "uber/inheritable_attr"
require "declarative/schema"
require "disposable/twin/definitions"
require "disposable/twin/collection"
require "disposable/twin/setup"
require "disposable/twin/sync"
require "disposable/twin/save"
require "disposable/twin/builder"
require "disposable/twin/changed"
require "disposable/twin/property_processor"
require "disposable/twin/persisted"
require "disposable/twin/default"

require "representable/decorator"

# Twin.new(model/composition hash/hash, options)
#   assign hash to @fields
#   write: write to @fields
#   sync/save is the only way to write back to the model.

module Disposable
  class Twin
    extend Declarative::Schema
    def self.definition_class
      Definition
    end

    def schema
      self.class.definitions.extend(DefinitionsEach)
    end

    class << self
      def default_nested_class
        Twin
      end

      # TODO: move to Declarative, as in Representable and Reform.
      def property(name, options={}, &block)
        options[:private_name] = options.delete(:from) || name

        if options.delete(:virtual)
          options[:writeable] = options[:readable] = false
        end

        options[:nested] = options.delete(:twin) if options[:twin]

        class_block = proc do
          require 'disposable/twin/struct'
          include Disposable::Twin::Struct if options[:struct]
          class_eval(&block)
        end if block

        super(name, options, &class_block).tap do |definition|
          create_accessors(name, definition)
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
          define_method("#{name}=") { |value| write_property(name, value, definition) }
        end
        include mod
      end
    end

    include Setup


    module Accessors
    private
      # assumption: collections are always initialized from Setup since we assume an empty [] for "nil"/uninitialized collections.
      def write_property(name, value, dfn)
        if dfn[:nested] and value
          value = dfn[:collection] ? wrap_collection(dfn, value) : wrap_scalar(dfn, value)
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

    class Twinner
      def initialize(dfn)
        @dfn = dfn
      end

      def call(value)
        @dfn[:nested].new(value)
      end
    end


  private
    module ModelReaders
      attr_reader :model # #model is a private concept.
      attr_reader :mapper
    end
    include ModelReaders
  end
end
