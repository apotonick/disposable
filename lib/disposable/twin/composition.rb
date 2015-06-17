require "disposable/expose"
require "disposable/composition"

module Disposable
  class Twin
    module Expose
      module ClassMethods
        def expose
          @expose ||= Class.new(Disposable::Expose).from(representer_class)
        end
      end

      def self.included(base)
        base.extend(ClassMethods)
      end


      def initialize(*args)
        super self.class.expose.new(*args)
      end
    end


    module Composition
      module ClassMethods
        def expose
          @expose ||= Class.new(Disposable::Composition).from(representer_class)
        end
      end

      def self.included(base)
        base.send(:include, Disposable::Twin::Expose)
        base.extend(ClassMethods)
      end
    end
  end
end