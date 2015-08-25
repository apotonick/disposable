# TODO: allow default: -> for hashes, etc.
module Disposable::Twin::Default
  def setup_value_for(dfn, options)
    value = super
    return value unless value.nil?
    default_for(dfn, options)
  end

  def default_for(dfn, options)
    dfn[:default].evaluate(self)
  end

  module ClassMethods
    def property(name, options={}, &block)
      options[:default] = Uber::Options::Value.new(options[:default])
      super
    end
  end

  def self.included(includer)
    includer.extend ClassMethods
  end
end
