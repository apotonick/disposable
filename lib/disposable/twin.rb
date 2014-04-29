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

    def self.property(name, options={}, &block)
      options[:public_name] = options.delete(:as) || name

      representer_class.property(name, options, &block).tap do |definition|
        attr_accessor definition[:public_name]
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

    # hash for #update_attributes (model API).
    def self.save_representer
      # TODO: do that only at compile-time!
      save = Class.new(write_representer) # inherit configuration
      save.representable_attrs.
        find_all { |attr| attr[:twin] }.
        each { |attr| attr.merge!(
          :representable => true) }

        save.representable_attrs.each do |attr|
          attr.merge!(:as => attr.name)
        end

      save
    end
    def to_hash(*) # DISCUSS: do we want that here?
      model
    end

    # transform incoming model into twin API hash.
    def self.new_representer
      representer = Class.new(representer_class) # inherit configuration

      # wrap incoming nested model in it's Twin.
      representer.representable_attrs.
        find_all { |attr| attr[:twin] }.
        each { |attr| attr.merge!(
          :pass_options => true,
          :prepare      => lambda { |object, args| args.binding[:twin].new(object) }) }

      # song_title => model.title
      representer.representable_attrs.each do |attr|
        attr.merge!(:as => attr[:public_name])
      end

      representer
    end

    # read/write to twin using twin's API (e.g. #record= not #album=).
    def self.write_representer
      representer = Class.new(representer_class) # inherit configuration
      representer.representable_attrs.
        each { |attr| attr.merge!(
          :pass_options => true,
          # use the alias name (as:) when writing attributes in new.
          # DISCUSS: attr.name = public_name would be simpler.
          :as => attr[:public_name],
          :getter      => lambda { |args|        send("#{args.binding[:public_name]}") },
          :setter      => lambda { |value, args| send("#{args.binding[:public_name]}=", value) }
        )}

      representer
    end

    def self.pre_save_representer
      representer = Class.new(write_representer)
      representer.representable_attrs.
        each { |attr| attr.merge!(
          :representable => true,
          :serialize => lambda { |model, args| puts model.inspect; model.save }
        )}

      representer
    end


    # it's important to stress that #save is the only entry point where we hit the database after initialize.
    def save # use that in Reform::AR.
      twin_names    = self.class.representer_class.twin_names
      twin_names = twin_names.collect { |n| n.to_sym }

      # raw_attrs     = self.class.write_representer.new(self).to_hash
      # save_attrs    = raw_attrs.select { |k| twin_names.include?(k) } # FIXME: bug when as and nested.
      # save_attrs.values.map(&:save)
      puts "iiiinclude #{twin_names.inspect}"
      self.class.pre_save_representer.new(self).to_hash(:include => twin_names) # #save on nested Twins.



      # what we do right now
      # call save on all nested twins - how does that work with dependencies (eg Album needs Song id)?
      # extract all ORM attributes
      # write to model

      sync_attrs    = self.class.save_representer.new(self).to_hash
      puts "sync> #{sync_attrs.inspect}"
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