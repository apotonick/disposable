require 'forwardable'

module Disposable
  # Composition delegates accessors to models as per configuration.
  #
  #   class Album
  #     include Disposable::Composition

  #     map( {cd: [:id, :name], band: [:title]} )
  #   end

  #   album = Album.new(cd: CD.find(1), band: Band.new)
  #   album.id #=> 1
  #   album.title = "Ten Foot Pole"
  module Composition
    def self.included(base)
      base.extend(Forwardable)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def map(options)
        @attr2obj = {}  # {song: {:id => :id, :name => :name}, artist: }

        options.each do |mdl, meths|
          create_accessors(mdl, meths)
          attr_reader mdl

          meths.each { |m| @attr2obj[m.to_s] = mdl }
        end
      end

      def create_accessors(model, methods)
        accessors = methods.collect { |m| [m, "#{m}="] }.flatten

        def_instance_delegator # where, meth, new_metho *accessors << {:to => :"#{model}"}
      end
    end


  private
    def initialize(models)
      models.each do |name, obj|
        instance_variable_set(:"@#{name}", obj)
      end

      @_models = models.values
    end

    attr_reader:_models
  end
end