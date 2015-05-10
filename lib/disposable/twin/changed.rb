module Disposable::Twin::Changed
  def changed?(name=nil)
    !! changed[name.to_s]
  end

  def changed
    @changed ||= {}
  end

private
  def initialize(model, *args)
    super # Initialize, Setup
    @changed = {}
  end

  def write_property(name, private_name, value, dfn)
    old_value = send(name) # FIXME: what about the private_name stuff?

    super.tap do
      changed[name.to_s] = old_value != value
    end
  end
end