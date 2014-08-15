module Disposable
  class Twin
        # call save on all nested twins.
    def self.pre_save_representer
      representer = Class.new(write_representer)
      representer.representable_attrs.
        each { |attr| attr.merge!(
          :representable => true,
          :serialize => lambda do |twin, args|
            processed = args.user_options[:processed_map]

            twin.save(processed) unless processed[twin] # don't call save if it is already scheduled.
          end
        )}

      representer
    end


    # it's important to stress that #save is the only entry point where we hit the database after initialize.
    def save(processed_map=ObjectMap.new) # use that in Reform::AR.
      processed_map[self] = true

      pre_save = self.class.pre_save_representer.new(self)
      pre_save.to_hash(:include => pre_save.twin_names, :processed_map => processed_map) # #save on nested Twins.



      # what we do right now
      # call save on all nested twins - how does that work with dependencies (eg Album needs Song id)?
      # extract all ORM attributes
      # write to model

      sync_attrs    = self.class.save_representer.new(self).to_hash
      # puts "sync> #{sync_attrs.inspect}"
      # this is ORM-specific:
      model.update_attributes(sync_attrs) # this also does `album: #<Album>`

      # FIXME: sync again, here, or just id?
      self.id = model.id
    end
  end
end