module Disposable
  # Composition delegates accessors to models as per configuration.
  module Composition
    module ClassMethods
    private
      def map(options)
        @attr2obj = {}  # {song: ["title", "track"], artist: ["name"]}

        options.each do |mdl, meths|
          create_accessors(mdl, meths)
          attr_reader mdl

          meths.each { |m| @attr2obj[m.to_s] = mdl }
        end
      end

      def create_accessors(model, methods)
        accessors = methods.collect { |m| [m, "#{m}="] }.flatten
        delegate *accessors << {:to => :"#{model}"}
      end
    end


    def initialize(models)
      models.each do |name, obj|
        instance_variable_set(:"@#{name}", obj)
      end
    end
  end
end