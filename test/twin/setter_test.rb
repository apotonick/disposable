require "test_helper"

class SetterTest < Minitest::Spec
  Composer = Struct.new(:name)

  class Twin < Disposable::Twin
    feature Setter

    property :name, setter: ->(v) { v.sub(/cat/, 'dog') unless v.nil? }
  end

  it do
    twin = Twin.new(Composer.new)
    twin.name = "cat"
    twin.name.must_equal "dog"
  end
end
