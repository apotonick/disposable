module Disposable::Twin::Parent
  def self.included(includer)
    includer.property(:parent, virtual: true)
  end

  # FIXME: for collections, this will merge options for every element.
  def build_twin(dfn, value, options={})
    super(dfn, value, options.merge(parent: self))
  end
end
