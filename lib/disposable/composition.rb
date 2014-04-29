require 'forwardable'

module Disposable
  # Composition delegates accessors to models as per configuration.
  # Composition doesn't know anything but methods (readers and writers) to expose and the mappings to
  # the internal models.
  # Furthemore, it knows about renamings such as mapping `#song_id` to `song.id`.
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
        # @attr2obj = {}

        options.each do |mdl, meths|
          attr_reader mdl

          meths.each do |mtd| # [[:title], [:id, :song_id]]
            create_accessors(mdl, mtd)
          end

          # meths.each { |m| @attr2obj[m.to_s] = mdl }
        end
      end

      def create_accessors(model, methods)
        def_instance_delegator model, *methods # reader
        def_instance_delegator model, *methods.map { |m| "#{m}=" } # writer
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