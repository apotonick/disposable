module Disposable::Twin::Save
  # Returns the result of that save invocation on the model.
  def save(options={}, &block)
    res = sync(&block)
    return res if block_given?

    save!(options)
  end

  def save!(options={})
    result = save_model

    save_representer.new(self).to_object # save! on all nested forms.

    dynamic_save!(options)

    result
  end

  def save_model
    model.save
  end


private
  def save_representer
    self.class.representer(:save, superclass: self.class.object_representer_class) do |dfn|
      dfn.merge!(
        prepare: lambda { |form, options| form.save! unless options.binding[:save] === false }
      )
    end
  end

  # DISCUSS: how do we do all the nested hash, dynamic options, etc.?
  def dynamic_save!(options)
    return # FIXME
    names = options.keys & changed.keys.map(&:to_sym)
    return if names.size == 0

    dynamic_save_representer.new(fields).to_hash(options.merge(:include => names))
  end

  def dynamic_save_representer
    self.class.representer(:dynamic_save, :all => true) do |dfn|
      dfn.merge!(
        :serialize     => lambda { |object, options| options.user_options[options.binding.name.to_sym].call(object, options) },
        :representable => true
      )
    end
  end
end
