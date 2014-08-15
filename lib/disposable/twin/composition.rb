module Disposable
  class Twin
    class Composition
      include Disposable::Composition

      def self.property(name, options, &block)
        map options[:on] => [[options[:as], name].compact] # why is Composition::map so awkward?
      end
      # TODO: test and implement ::collection
    end
  end
end