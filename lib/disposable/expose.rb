module Disposable
  class Expose
    class << self
      def from(representer)
        representer.representable_attrs.each do |definition|
          process_definition!(definition)
        end
      end

    private
      def process_definition!(definition)
        public_name  = definition.name
        private_name = definition[:private_name] || public_name

        accessors!(public_name, private_name, definition)
      end

      def accessors!(public_name, private_name, definition)
        define_method("#{public_name}")  { @model.send("#{private_name}") }
        define_method("#{public_name}=") { |*args| @model.send("#{private_name}=", *args) }
      end
    end


    def initialize(model)
      @model = model
    end
  end
end