module Disposable
  class Twin
  # Provides collection semantics like add, delete, and more for twin collections.
    class Collection < Array
      def <<(model)
        super(TwinCollectionActiveRecordTest::Twin::Song.new(model))
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