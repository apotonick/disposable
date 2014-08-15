module Disposable
  class Twin
        # transform incoming model into twin API hash.
    def self.new_representer
      representer = Class.new(representer_class) # inherit configuration

      # wrap incoming nested model in its Twin.
      representer.representable_attrs.
        find_all { |attr| attr[:twin] }.
        each { |attr| attr.merge!(
          :prepare      => lambda { |object, args|
            if twin = args.user_options[:object_map][object]
              twin
            else
              args.binding[:twin].evaluate(nil).new(object, args.user_options[:object_map])
            end
          }) }

      # song_title => model.title
      representer.representable_attrs.each do |attr|
        attr.merge!(
          :getter => lambda { |args|
            args.represented.send("#{args.binding[:private_name]}") }, # DISCUSS: can't we do that with representable's mechanics?
        )
      end

      representer
    end
  end
end