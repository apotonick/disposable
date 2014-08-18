require 'uber/inheritable_attr'
require 'representable/decorator'
require 'representable/hash'
require 'disposable/twin/representer'

module Disposable
  class Twin
    extend Uber::InheritableAttr
    inheritable_attr :representer_class
    self.representer_class = Class.new(Decorator)


    def self.property(name, options={}, &block)
      options[:private_name]  = options.delete(:as) || name
      options[:pass_options] = true

      representer_class.property(name, options, &block).tap do |definition|
        mod = Module.new do
          define_method(name)       { read_property(name, options[:private_name]) }
          define_method("#{name}=") { |value| write_property(name, options[:private_name], value, definition[:readable]) } # TODO: this is more like prototyping.
        end
        include mod
      end
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

    def write_property(name, private_name, value, readable)
      return @fields[name.to_s] = value if readable == false # FIXME: this is for Option and i'll clean this up.
       # this will soon be overridable so ORM Twins can delay writing till #sync or #save.
       @fields[name.to_s] = write_to_model(private_name, value)
    end

    def write_to_model(setter, value)
      model.send("#{setter}=", value)
      value
    end

    def from_hash(options)
      self.class.write_representer.new(self).from_hash(options)
    end

    attr_reader :model # TODO: test
  end
end