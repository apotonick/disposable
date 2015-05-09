module Disposable::Twin::Changed
  def changed?(name=nil)
    # puts "+++#{model.class}  #{name}: #{changed.inspect} (in #{model.class})"
    !! changed[name.to_s]
  end

  def changed
    # puts "++%%%+#{model.class} "
    @changed ||= {}
  end

private
  def initialize(model, *args)
    super # Initialize, Setup

    puts "#{model.class} Changed#initialize"
    @changed = {}
  end

  def write_property(name, private_name, value, dfn)
    old_value = send(name) # FIXME: what about the private_name stuff?

    super.tap do
      # puts "comparing #{old_value} and #{value}"
      changed[name.to_s] = old_value != value
    end
  end
end