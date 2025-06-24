module Disposable::Twin::Changed
  def changes(name=nil)
    _find_changed_twins!(_changes)

    return _changes unless name
    _changes[name.to_s]
  end

  def changed?(name=nil)
    _find_changed_twins!(_changes)

    (name.nil? && _changes.values.any?) || _changes.has_key?(name.to_s)
  end

private

  attr_reader :_changes
  def initialize(model, *args)
    super          # Setup#initialize.
    @_changes = {} # override changed from initialize.
  end

  def write_property(name, value, dfn)
    old_value = field_read(name)
    return if old_value == value

    super.tap do
      @_changes ||= {}
      _changes[name.to_s] = [old_value, value]
    end
  end

  def _find_changed_twins!(changes) # FIXME: this will change soon. don't touch.
    schema.each(twin: true) do |dfn|
      next unless twin = send(dfn.getter)
      next unless twin.changed?

      if twin.is_a?(Disposable::Twin::Collection)
        changes[dfn[:name]] = []
        twin.each do |item|
          changes[dfn[:name]] << item.changes
        end
      else
        changes[dfn[:name]] = twin.changes
      end
    end
  end
end
