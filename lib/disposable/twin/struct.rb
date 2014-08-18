module Disposable
  class Twin
    module Struct
      def initialize(options={})
        super
        from_hash(options)
      end

    private
      def read_from_model(name)
      end

      def write_to_model(name, value)
        value
      end
    end
  end
end