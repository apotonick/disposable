# TODO: this needs tests and should probably go to Representable. we can move tests from Reform for that.
class Disposable::Twin::Schema
  def self.from(source_class, options) # TODO: can we re-use this for all the decorator logic in #validate, etc?
    representer = Class.new(options[:superclass])
    representer.send :include, *options[:include]

    source_class.representable_attrs.each do |dfn|
      local_options = dfn[options[:options_from]] || {} # e.g. deserializer: {..}.
      new_options   = dfn.instance_variable_get(:@options).merge(local_options)

      from_scalar!(options, dfn, new_options, representer) && next unless dfn[:extend]

      from_inline!(options, dfn, new_options, representer)
    end

    representer
  end

private
  def self.from_scalar!(options, dfn, new_options, representer)
    representer.property(dfn.name, new_options)
  end

  def self.from_inline!(options, dfn, new_options, representer)
    nested             = dfn[:extend].evaluate(nil) # nested now can be a Decorator, a representer module, a Form, a Twin.
    nested_representer = options[:representer_from].call(nested) # e.g. nested.twin_representer_class, whatever returns an object with #representable_attrs.

    dfn_options = new_options.merge(extend: from(nested_representer, options))

    representer.property(dfn.name, dfn_options)
  end
end