module Disposable::Twin::Changed
  def changed?(name=nil)
    # TODO: performance? changed should be called just once, per sync, per twin?
    _find_changed_twins!

    return true if name.nil? and changed.size > 0
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

  def _find_changed_twins! # FIXME: this will change soon. don't touch.
    # TODO: screw representers for 1-level data-transformations and use something simpler, faster?
    self.class.representer_class.representable_attrs.find_all do |dfn|
      dfn[:twin]
    end.each do |dfn|
      next unless twin = send(dfn.getter)
      next unless twin.changed?

      changed[dfn.name] = true
      changed["self"] = true
    end
  end
end