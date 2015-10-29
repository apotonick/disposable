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

require "declarative/schema"

# Twin.new(model/composition hash/hash, options)
#   assign hash to @fields
#   write: write to @fields
#   sync/save is the only way to write back to the model.

module Disposable
  class Twin
    extend Uber::InheritableAttr

    extend Declarative::Schema::DSL
    extend Declarative::Schema::Feature # TODO: make automatic
    extend Declarative::Schema::Heritage # TODO: make automatic

    def schema
      self.class.definitions.values.instance_exec do
        def each(options={})
          return self unless block_given?

          super() do |dfn|
            next if options[:exclude]    and options[:exclude].include?(dfn[:name])
            next if options[:scalar]     and dfn[:collection]
            next if options[:collection] and ! dfn[:collection]
            next if options[:twin]       and ! dfn[:nested]

            yield dfn
          end

          self
        end
        self
      end
    end

    class << self
      def default_nested_class
        Twin
      end

      # TODO: move to Declarative, as in Representable and Reform.
      def property(name, options={}, &block)
        puts "@@@@@ #{name.inspect}"
        options[:private_name] = options.delete(:from) || name

        if options.delete(:virtual)
          options[:writeable] = options[:readable] = false
        end

        # FIXME: now it's evaluated at compile-time!
        options[:nested] = Uber::Options::Value.new(options[:twin]).(nil) # e.g. property :album, twin: Album.

        super(name, options, &block).tap do |definition|
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
        @dfn[:nested].new(value)
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