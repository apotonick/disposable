module Disposable::Twin::Parent
  def self.included(includer)
    includer.property(:parent, virtual: true)
  end

  def build_twin(dfn, value, options={})
    super(dfn, value, options.merge(parent: self))
  end
end
