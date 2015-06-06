# TODO: this needs tests and should probably go to Representable. we can move tests from Reform for that.
class Disposable::Twin::Schema
  def self.from(source_class, options) # TODO: can we re-use this for all the decorator logic in #validate, etc?
    representer = Class.new(options[:superclass])
    representer.send :include, *options[:include]

    source_class.representable_attrs.each do |dfn|
      representer.property(dfn.name, dfn.instance_variable_get(:@options)) unless dfn[:extend]

      if twin = dfn[:twin]
        twin = twin.evaluate(nil)

        dfn_options = dfn.instance_variable_get(:@options).merge(extend: from(twin.representer_class, options))

        if dfn_options[:deserializer]
          dfn_options.merge!(dfn_options[:deserializer])
        end

        representer.property(dfn.name, dfn_options)
      end
    end

    representer
  end
end