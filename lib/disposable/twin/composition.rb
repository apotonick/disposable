module Disposable
  class Twin
    class Composition
      include Disposable::Composition

      extend Uber::InheritableAttr
      inheritable_attr :twin_classes
      self.twin_classes = {}

      # this creates one Twin per composed.
      def self.property(name, options, &block)
        twin_classes[options[:on]] ||= Class.new(Twin)
        twin_classes[options[:on]].property(name, options, &block)

        map options[:on] => [[name]] # why is Composition::map so awkward?
      end
      # TODO: test and implement ::collection

      def initialize(composed)
        twins = {}
        composed.each { |name, model| twins[name] = self.class.twin_classes[name].new(model) }

        super(twins)
      end
    end
  end
end