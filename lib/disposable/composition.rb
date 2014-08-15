require 'forwardable'

module Disposable
  # Composition delegates accessors to models as per configuration.
  #
  # Composition doesn't know anything but methods (readers and writers) to expose and the mappings to
  # the internal models. Optionally, it knows about renamings such as mapping `#song_id` to `song.id`.
  #
  #   class Album
  #     include Disposable::Composition
  #
  #     map( {cd: [[:id], [:name]], band: [[:id, :band_id], [:title]]} )
  #   end
  #
  # Composition adds #initialize to the includer.
  #
  #   album = Album.new(cd: CD.find(1), band: Band.new)
  #   album.id #=> 1
  #   album.title = "Ten Foot Pole"
  #   album.band_id #=> nil
  #
  # It allows accessing the contained models using the `#[]` reader.
  module Composition
    def self.included(base)
      base.extend(Forwardable)
      base.extend(ClassMethods)
    end


    module ClassMethods
      def map(options)
         @map = {}

        options.each do |mdl, meths|
          meths.each do |mtd| # [[:title], [:id, :song_id]]
            create_accessors(mdl, mtd)
            add_to_map(mdl, mtd)
          end
        end
      end

    private
      def create_accessors(model, methods)
        def_instance_delegator "@#{model}", *methods # reader
        def_instance_delegator "@#{model}", *methods.map { |m| "#{m}=" } # writer
      end

      def add_to_map(model, methods)
        name, public_name = methods
        public_name     ||= name

        @map[public_name.to_sym] = {:method => name.to_sym, :model => model.to_sym}
      end
    end


    def initialize(models)
      models.each do |name, obj|
        instance_variable_set(:"@#{name}", obj)
      end

      @_models = models.values
    end

    # Allows accessing the contained models.
    def [](name)
      instance_variable_get(:"@#{name}")
    end

    # Allows multiplexing method calls to all composed models.
    def each(&block)
      _models.each(&block)
    end

  private
    attr_reader :_models
  end
end