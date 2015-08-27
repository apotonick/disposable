# TODO: allow default: -> for hashes, etc.
module Disposable::Twin::Default
  def setup_value_for(dfn, options)
    value = super
    return value unless value.nil?
    default_for(dfn, options)
  end

  def default_for(dfn, options)
    # TODO: introduce Null object in Declarative::Definition#[].
    # dfn[:default].(self) # dfn#[] should return a Null object here if empty.
    return unless dfn[:default]
    dfn[:default].evaluate(self) # TODO: use .()
  end

  module ClassMethods
    def property(name, options={}, &block)
      options[:default] = Uber::Options::Value.new(options[:default]) if options[:default]
      super
    end
  end

  def self.included(includer)
    includer.extend ClassMethods
  end
end
