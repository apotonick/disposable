module Disposable
  class Twin
  # Provides collection semantics like add, delete, and more for twin collections.
    class Collection < Array
      def initialize(twin_class, items)
        super(items)
        @twin_class = twin_class
      end

      def <<(model)
        super(twin_class.new(model)) # DISCUSS: Collection twins the model for us - is that what we really want?
      end

      # Remove an item from a collection. This will not destroy the model.
      def delete(model)
        super(find { |twin| twin.send(:model) == model })
      end

      # Deletes twin from collection and destroys it in #save.
      def destroy(model)
        twin = find { |twin| twin.send(:model) == model }

        delete(model)
        to_destroy << twin
      end

      def save
        to_destroy.each { |twin| twin.send(:model).destroy }
      end

    private
      def to_destroy
        @to_destroy ||= []
      end

      def twin_class
        @twin_class.evaluate(nil) # DISCUSS: what context do we want here?
      end


      module Semantics
        def save
          super.tap do
            songs.save
          end
        end
      end
    end
  end
end