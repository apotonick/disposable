# module Disposable
#   class Twin
#         # call save on all nested twins.
#     def self.pre_save_representer
#       representer = Class.new(write_representer)
#       representer.representable_attrs.
#         each { |attr| attr.merge!(
#           :representable => true,
#           :serialize => lambda do |twin, args|
#             processed = args.user_options[:processed_map]

#             twin.save(processed) unless processed[twin] # don't call save if it is already scheduled.
#           end
#         )}

#       representer
#     end


#     # it's important to stress that #save is the only entry point where we hit the database after initialize.
#     def save(processed_map=ObjectMap.new) # use that in Reform::AR.
#       processed_map[self] = true

#       pre_save = self.class.pre_save_representer.new(self)
#       pre_save.to_hash(:include => pre_save.twin_names, :processed_map => processed_map) # #save on nested Twins.



#       # what we do right now
#       # call save on all nested twins - how does that work with dependencies (eg Album needs Song id)?
#       # extract all ORM attributes
#       # write to model

#       sync_attrs    = self.class.save_representer.new(self).to_hash
#       # puts "sync> #{sync_attrs.inspect}"
#       # this is ORM-specific:
#       model.update_attributes(sync_attrs) # this also does `album: #<Album>`

#       # FIXME: sync again, here, or just id?
#       self.id = model.id
#     end
#   end
# end
module Disposable::Twin::Save
  # Returns the result of that save invocation on the model.
  def save(options={}, &block)
    # DISCUSS: we should never hit @mapper here (which writes to the models) when a block is passed.
    return yield to_nested_hash if block_given?

    sync_models # recursion
    save!(options)
  end

  def save!(options={}) # FIXME.
    result = save_model

    save_representer.new(self).to_hash # save! on all nested forms.

    dynamic_save!(options)

    result
  end

  def save_model
    model.save # TODO: implement nested (that should really be done by Twin/AR).
  end


  require "active_support/hash_with_indifferent_access" # DISCUSS: replace?
  def to_nested_hash(*)
    ActiveSupport::HashWithIndifferentAccess.new(nested_hash_representer.new(fields).to_hash)
  end
  alias_method :to_hash, :to_nested_hash
  # NOTE: it is not recommended using #to_hash and #to_nested_hash in your code, consider them private.

private
  def save_representer
    self.class.representer(:save) do |dfn|
      dfn.merge!(
        :instance  => lambda { |form, *| form },
        :serialize => lambda { |form, args| form.save! unless args.binding[:save] === false }
      )
    end
  end

  def nested_hash_representer
    self.class.representer(:nested_hash, :all => true) do |dfn|
      dfn.merge!(:serialize => lambda { |form, args| form.to_nested_hash }) if dfn[:form]

      dfn.merge!(:as => dfn[:private_name] || dfn.name)
    end
  end

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
