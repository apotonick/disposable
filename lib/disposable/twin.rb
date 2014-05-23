require 'uber/inheritable_attr'
require 'representable/decorator'
require 'representable/hash'

module Disposable
  class Twin
    class Definition < Representable::Definition
      def dynamic_options
        super + [:twin]
      end
    end


    class Decorator < Representable::Decorator
      include Representable::Hash
      include AllowSymbols

      # DISCUSS: same in reform, is that a bug in represntable?
      def self.clone # called in inheritable_attr :representer_class.
        Class.new(self) # By subclassing, representable_attrs.clone is called.
      end

      def self.definition_class
        Definition
      end

      def twin_names
        representable_attrs.
          find_all { |attr| attr[:twin] }.
          collect { |attr| attr.name.to_sym }
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
      options[:private_name]  = options.delete(:as) || name
      options[:pass_options] = true

      representer_class.property(name, options, &block).tap do |definition|
        attr_accessor name
      end
    end

    def self.collection(name, options={}, &block)
      property(name, options.merge(:collection => true), &block)
    end

    # this method should only be called in finders, and considered semi-private. it should only be called once as the top stack entry.
    def self.from(model) # TODO: private.
      new(model)
    end

    def self.new(model={}, object_map=ObjectMap.new)
      super(model, object_map)
    end


    # TODO: improve speed when setting up a twin.
    def initialize(model, object_map)
      options = {}
      options, model = model, self.class._model.new if model.is_a?(Hash)


      # model, options = nil, model if model.is_a?(Hash) # sorry but i wanna have the same API as ActiveRecord here.
      @model = model #|| self.class._model.new

      object_map[@model] = self # DISCUSS: how to we handle compositions here?

      from_hash(
        self.class.new_representer.new(@model).to_hash(:object_map => object_map). # always read from model, even when it's new.
        merge(options)
      )
    end

    def self.find(id)
      new(_model.find(id))
    end

    # hash for #update_attributes (model API): {title: "Future World", album: <Album>}
    def self.save_representer
      # TODO: do that only at compile-time!
      save = Class.new(write_representer) # inherit configuration
      save.representable_attrs.
        find_all { |attr| attr[:twin] }.
        each { |attr| attr.merge!(
          :representable => true,
          :serialize     => lambda { |obj, args| obj.send(:model) }) }

        save.representable_attrs.each do |attr|
          attr.merge!(:as => attr[:private_name])
        end

      save
    end

    # transform incoming model into twin API hash.
    def self.new_representer
      representer = Class.new(representer_class) # inherit configuration

      # wrap incoming nested model in its Twin.
      representer.representable_attrs.
        find_all { |attr| attr[:twin] }.
        each { |attr| attr.merge!(
          :prepare      => lambda { |object, args|
            if twin = args.user_options[:object_map][object]
              twin
            else
              args.binding[:twin].evaluate(nil).new(object, args.user_options[:object_map])
            end
          }) }

      # song_title => model.title
      representer.representable_attrs.each do |attr|
        attr.merge!(
          :getter      => lambda { |args| send("#{args.binding[:private_name]}") },
        )
      end

      representer
    end

    # read/write to twin using twin's API (e.g. #record= not #album=).
    def self.write_representer
      representer = Class.new(representer_class) # inherit configuration
    end

    # call save on all nested twins.
    def self.pre_save_representer
      representer = Class.new(write_representer)
      representer.representable_attrs.
        each { |attr| attr.merge!(
          :representable => true,
          :serialize => lambda { |model, args| model.save }
        )}

      representer
    end


    # it's important to stress that #save is the only entry point where we hit the database after initialize.
    def save # use that in Reform::AR.
      pre_save = self.class.pre_save_representer.new(self)
      pre_save.to_hash(:include => pre_save.twin_names) # #save on nested Twins.



      # what we do right now
      # call save on all nested twins - how does that work with dependencies (eg Album needs Song id)?
      # extract all ORM attributes
      # write to model

      sync_attrs    = self.class.save_representer.new(self).to_hash
      # puts "sync> #{sync_attrs.inspect}"
      # this is ORM-specific:
      model.update_attributes(sync_attrs) # this also does `album: #<Album>`

      # FIXME: sync again, here, or just id?
      self.id = model.id
    end

  private
    def from_hash(options={})
      self.class.write_representer.new(self).from_hash(options)
    end

    attr_reader :model # TODO: test


    class ObjectMap < Hash
    end

    # class Composition < self
    #   def initialize(hash)
    #     hash = hash.first
    #     composition = Class.new do
    #       include Disposable::Composition
    #       map( {:song => [:song_title], :requester => [:name]})
    #       self
    #     end.new(hash)

    #     super(composition)
    #   end
    # end
  end
end