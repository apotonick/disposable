module Disposable
  class Twin
    module Composition
      module ClassMethods
        def composition
          @composition ||= Class.new(Disposable::Composition).from(representer_class)
        end
      end

      def self.included(base)
        base.extend(ClassMethods)
      end


      def initialize(*args)
        super self.class.composition.new(*args)
      end
    end
  end
end