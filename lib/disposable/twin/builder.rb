require "uber/builder"

module Disposable
  class Twin
    # Allows building different twin classes.
    #
    #   class SongTwin < Disposable::Twin
    #     include Builder
    #     builds ->(model, options) do
    #       return Hit       if model.is_a? Model::Hit
    #       return Evergreen if options[:evergreen]
    #     end
    #   end
    #
    #   SongTwin.build(Model::Hit.new) #=> <Hit>
    module Builder
      def self.included(base)
        base.class_eval do
          include Uber::Builder

          def self.build(model, options={}) # semi-public.
            class_builder.call(model, options).new(model, options) # Uber::Builder::class_builder.
          end
        end
      end
    end
  end
end