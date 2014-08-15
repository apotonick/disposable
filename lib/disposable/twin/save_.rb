module Disposable
  class Twin
    # hash for #update_attributes (model API): {title: "Future World", album: <Album>}
    def self.save_representer
      # TODO: do that only at compile-time!
      save = Class.new(write_representer) # inherit configuration
      save.representable_attrs.
        find_all { |attr| attr[:twin] }.
        each { |attr| attr.merge!(
          :representable => true,
          :serialize     => lambda { |obj, args| obj.send(:model) }) }

        save.representable_attrs.each do |attr|
          attr.merge!(:as => attr[:private_name])
        end

      save
    end

  end
end