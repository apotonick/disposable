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
  class Composition < Expose
    def initialize(models)
      models.each do |name, model|
        instance_variable_set(:"@#{name}", model)
      end

      @_models = models
    end

    # Allows accessing the contained models.
    def [](name)
      instance_variable_get("@#{name}")
    end

    def each(&block)
      # TODO: test me.
      @_models.values.each(&block)
    end

  private
    def self.accessors!(public_name, private_name, definition)
      model = definition[:on]
      define_method("#{public_name}")  { self[model].send("#{private_name}") }
      define_method("#{public_name}=") { |*args| self[model].send("#{private_name}=", *args) }
    end
  end
end