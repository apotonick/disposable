require 'uber/inheritable_attr'
require 'representable/decorator'
require 'representable/hash'

module Disposable
  class Twin
    class Decorator < Representable::Decorator
      include Representable::Hash
      include AllowSymbols

      # DISCUSS: same in reform, is that a bug in represntable?
      def self.clone # called in inheritable_attr :representer_class.
        Class.new(self) # By subclassing, representable_attrs.clone is called.
      end

      def self.build_config
        super.extend(ConfigExtensions)
      end

      def self.twin_names
        representable_attrs.twin_names
      end

      def twins(&block)
        clone_config!.
            find_all { |attr| attr[:form] }.
            each(&block)
        end

      module ConfigExtensions
        def twin_names
          find_all { |attr| attr[:twin] }.
          collect { |attr| attr.name }
        end
      end


      class Save < self

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
      representer_class.property(name, *args, &block).tap do |definition|
        attr_accessor definition[:as].evaluate(nil)
      end
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

    def self.save_representer
      # TODO: do that only at compile-time!
      save = Class.new(representer_class) # inherit configuration
      save.representable_attrs.
        find_all { |attr| attr[:twin] }.
        each { |attr| attr.merge!(
          :representable => true) }
      save
    end

    def self.new_representer
      representer = Class.new(representer_class) # inherit configuration
      representer.representable_attrs.
        find_all { |attr| attr[:twin] }.
        each { |attr| attr.merge!(
          :pass_options => true,
          :prepare      => lambda { |object, args| args.binding[:twin].new(object) }) }
      representer
    end

    def self.write_representer
      representer = Class.new(representer_class) # inherit configuration
      representer.representable_attrs.
        each { |attr| attr.merge!(
          :pass_options => true,
          # use the alias name (as:) when writing attributes in new.
          :getter      => lambda { |args| send("#{args.binding[:as].evaluate(nil)}") },
          :setter      => lambda { |value, args| send("#{args.binding[:as].evaluate(nil)}=", value) } )}

      representer
    end


    def to_hash(*) # DISCUSS: do we want that here?
      model
    end

    # it's important to stress that #save is the only entry point where we hit the database after initialize.
    def save # use that in Reform::AR.
      twin_names    = self.class.representer_class.twin_names

      raw_attrs     = self.class.write_representer.new(self).to_hash
      save_attrs    = raw_attrs.select { |k| twin_names.include?(k) } # FIXME: bug when as and nested.
      save_attrs.values.map(&:save)


      sync_attrs    = self.class.save_representer.new(self).to_hash
      # this is ORM-specific:
      model.update_attributes(sync_attrs) # this also does `album: #<Album>`

      # FIXME: sync again, here, or just id?
      self.id = model.id
    end

    # below is the code for a representable-style twin:

    # TODO: improve speed when setting up a twin.
    def initialize(model, options={})
      @model = model

      # DISCUSS: does the case exist where we get model AND options? if yes, test. if no, we can save the mapping and just use options.
      from_hash(self.class.new_representer.new(model).to_hash.
        merge(options))
    end

  private
    def from_hash(options={})
      self.class.write_representer.new(self).from_hash(options)
    end

    attr_reader :model # TODO: test
  end
end