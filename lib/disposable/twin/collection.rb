module Disposable
  class Twin
  # Provides collection semantics like add, delete, and more for twin collections.
    class Collection < Array
      def initialize(wrapper, items)
        super(items)
        @wrapper = wrapper
      end

      def <<(model)
        super(@wrapper.(model))
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
            collection_save_representer.new(self).to_hash # calls #save on all collections.
          end
        end

      private
        def collection_save_representer
          self.class.representer(:collection_save) do |dfn| # only nested twins.
            dfn.merge!(
              :render_filter => lambda { |collection, *args| collection.save }, # songs.save
            ) if dfn.array?
          end
        end
      end
    end
  end
end