module Disposable
  class Twin
  # Provides collection semantics like add, delete, and more for twin collections.
  # Note: this API is highly prototypical and might change soon when i know what i want.
  #       use at your own risk! i'm not sure whether models or twins are the "main" api elements for this.
    class Collection < Array
      def self.for_models(twinner, models)
        new(twinner, models.collect { |model| twinner.(model) })
      end

      def initialize(twinner, items)
        super(items)
        @twinner = twinner # DISCUSS: twin items here?
      end

      # Note that this expects a model, untwinned.
      def <<(model)
        super(@twinner.(model))
      end

      # Note that this expects a model, untwinned.
      def insert(index, model)
        super(index, twin = @twinner.(model))
        twin
      end

      # Remove an item from a collection. This will not destroy the model.
      def delete(twin)
        super(twin)
      end

      # Deletes twin from collection and destroys it in #save.
      def destroy(twin)
        delete(twin)
        to_destroy << twin
      end

      def save
        to_destroy.each { |twin| twin.send(:model).destroy }
      end

      module Changed
        # FIXME: this should not be included automatically, as Changed is a feature.
        def changed?
          find { |twin| twin.changed? }
        end
      end
      include Changed

    private
      def to_destroy
        @to_destroy ||= []
      end


      module Semantics
        def save
          super.tap do
            schema.each(collection: true) do |dfn|
              send(dfn.getter).save
            end
          end
        end
      end # Semantics.
    end
  end
end