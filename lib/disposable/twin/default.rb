# TODO: allow default: -> for hashes, etc.
module Disposable::Twin::Default
  def setup_value_for(dfn, options)
    value = super
    return value unless value.nil?
    default_for(dfn, options)
  end

  def default_for(dfn, options)
    Uber::Options::Value.new(dfn[:default]).evaluate(self)
  end
end
