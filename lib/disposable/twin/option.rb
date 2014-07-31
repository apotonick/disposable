module Disposable::Twin::Option
  def self.included(base)
    base.extend ClassMethods
  end


  def setup!(model, options)
    # FIXME: merge that with original Twin.

    @model = model #|| self.class._model.new

    from_hash(
      self.class.new_representer.new(@model).to_hash
    )

    # TODO: just make new_representer with :getter for option!
    # IDEA: how can we bring that in line with Composition?
    from_hash(options)
  end

  module ClassMethods
    def option(name, options={})
      property(name, options.merge(:readable => false))
    end
  end
end