require 'forwardable'

module Disposable
  # Composition delegates accessors to models as per configuration.
  # Composition doesn't know anything but methods (readers and writers) to expose and the mappings to
  # the internal models. Optionally, it knows about renamings such as mapping `#song_id` to `song.id`.
  #
  #   class Album
  #     include Disposable::Composition
  #
  #     map( {cd: [[:id], [:name]], band: [[:id, :band_id], [:title]]} )
  #   end
  #
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
         @map = {}

        options.each do |mdl, meths|
          attr_reader mdl

          meths.each do |mtd| # [[:title], [:id, :song_id]]
            create_accessors(mdl, mtd)
            add_to_map(mdl, mtd)
          end
        end
      end

    private
      def create_accessors(model, methods)
        def_instance_delegator model, *methods # reader
        def_instance_delegator model, *methods.map { |m| "#{m}=" } # writer
      end

      def add_to_map(model, methods)
        name, public_name = methods
        public_name     ||= name

        @map[public_name.to_sym] = {:method => name, :model => model}
      end
    end


    def initialize(models)
      models.each do |name, obj|
        instance_variable_set(:"@#{name}", obj)
      end

      @_models = models.values
    end

  private
    attr_reader:_models
  end
end