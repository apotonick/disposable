module Disposable
  class Expose
    def self.from(representer)
      representer.representable_attrs.each do |definition|
        process_definition!(definition)
      end
    end

  private
    def self.process_definition!(definition)
      public_name  = definition.name
      private_name = definition[:private_name] || public_name

      define_method("#{public_name}")  { @model.send("#{private_name}") }
      define_method("#{public_name}=") { |*args| @model.send("#{private_name}=", *args) }
    end

    def initialize(model)
      @model = model
    end
  end
end