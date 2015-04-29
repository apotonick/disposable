require 'uber/inheritable_attr'
require 'representable/decorator'
require 'representable/hash'
require 'disposable/twin/representer'
require 'disposable/twin/option'
require 'disposable/twin/builder'

# Twin.new(model/composition hash/hash, options)
#   assign hash to @fields
#   write: write to @fields
#   sync/save is the only way to write back to the model.

module Disposable
  class Twin
    extend Uber::InheritableAttr
    inheritable_attr :representer_class
    self.representer_class = Class.new(Decorator)


    # FIXME: just prototyping!
    inheritable_attr :object_representer_class
    self.object_representer_class = Class.new(ObjectDecorator)


    def self.property(name, options={}, &block)
      options[:private_name] = options.delete(:as) || name
      options[:pass_options] = true

      representer_class.property(name, options, &block).tap do |definition|
        mod = Module.new do
          define_method(name)       { read_property(name, options[:private_name]) }
          define_method("#{name}=") { |value| write_property(name, options[:private_name], value) } # TODO: this is more like prototyping.
        end
        include mod
      end




      object_representer_class.property(name, options, &block)
    end

    def self.collection(name, options={}, &block)
      property(name, options.merge(:collection => true), &block)
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

      @fields[name.to_s] = read_from_model(private_name)
    end

    def read_from_model(getter)
      model.send(getter)
    end

    def write_property(name, private_name, value)
       @fields[name.to_s] = value
    end

    def from_hash(options)
      self.class.write_representer.new(self).from_hash(options)
    end

    attr_reader :model # TODO: test

    include Option



    # Provides collection semantics like add, delete, and more for twin collections.
    class Collection < Array
      def <<(model)
        super(TwinCollectionActiveRecordTest::Twin::Song.new(model))
      end

      # Remove an item from a collection. This will not destroy the model.
      def delete(model)
        super(find { |twin| twin.send(:model) == model })
      end

      def destroy(model)
        twin = find { |twin| twin.send(:model) == model }
        delete(model)


        to_destroy << twin
      end

      def save
        to_destroy.each { |twin| twin.send(:model).destroy }
      end

    private
      def to_destroy
        @to_destroy ||= []
      end


      module Semantics
        def save
          super.tap do
            songs.save
          end
        end
      end
    end
  end
end