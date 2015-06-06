require "test_helper"

class TwinBuilderTest < MiniTest::Spec
  class Twin < Disposable::Twin
    property :id
    property :title
    # option   :is_released
  end

  describe "without property setup" do
    class Host
      include Disposable::Twin::Builder

      twin Twin

      def initialize(*args)
        @model = build_twin(*args)
      end

      attr_reader :model
    end

    subject { Host.new(TwinTest::Model::Song.new(1, "Saturday Night"), is_released: true) }

    # model is simply the twin.
    it { subject.respond_to?(:title).must_equal false }
    it { subject.model.id.must_equal 1 }
    it { subject.model.title.must_equal "Saturday Night" }
    it { subject.model.is_released.must_equal true }
  end


  describe "without property setup" do
    class HostWithReaders
      include Disposable::Twin::Builder

      extend Forwardable
      twin(Twin) { |dfn| def_delegator :@model, dfn.name }

      def initialize(*args)
        @model = build_twin(*args)
      end
    end

    subject { HostWithReaders.new(TwinTest::Model::Song.new(1, "Saturday Night"), is_released: true) }

    # both twin gets created and reader method defined.
    it { subject.id.must_equal 1 }
    it { subject.title.must_equal "Saturday Night" }
    # it { subject.is_released.must_equal true }
  end
end
