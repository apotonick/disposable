module Disposable::Twin::Finders
  def find(*args)
    finders.find(*args)
  end

  # Use Song::Twin.finders.where(..) or whatever finder/scope is defined in the model.
  # It will return each model wrapped in a Twin.
  def finders
    FinderBuilder.new(self, _model)
  end

  class FinderBuilder
    def initialize(*args)
      @twin_class, @model_class = *args
    end

  private
    def method_missing(*args, &block)
      models = execute(*args, &block)

      return @twin_class.new(models) unless models.respond_to?(:each) # sorry for all the magic, but that's how ActiveRecord works.
      models.collect { |mdl| @twin_class.new(mdl) }
    end

    def execute(*args, &block)
      @model_class.send(*args, &block)
    end
  end
end