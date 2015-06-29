require "test_helper"

require "disposable/twin/coercion"

class CoercionTest < MiniTest::Spec
  Band = Struct.new(:label)

  class Irreversible < Virtus::Attribute
    def coerce(value)
      value*2
    end
  end

  class Twin < Disposable::Twin
    feature Coercion
    feature Setup::SkipSetter

    property :id
    property :released_at, :type => DateTime

    property :hit do
      property :length, :type => Integer
      property :good,   :type => Virtus::Attribute::Boolean
    end

    property :band do
      property :label do
        property :value, :type => Irreversible
      end
    end
  end

  subject do
    Twin.new(album)
  end

  let (:album) {
    OpenStruct.new(
      id: 1,
      :released_at => "31/03/1981",
      :hit         => OpenStruct.new(:length => "312"),
      :band        => Band.new(OpenStruct.new(:value => "9999.99"))
    )
  }

  # it { subject.released_at.must_be_kind_of DateTime }
  it { subject.released_at.must_equal "31/03/1981" } # NO coercion in setup.
  it { subject.hit.length.must_equal "312" }
  it { subject.band.label.value.must_equal "9999.99" }


  it do
    subject.id = Object
    subject.released_at = "30/03/1981"
    subject.hit.length = "312"
    subject.band.label.value = "9999.99"

    subject.id = Object
    subject.released_at.must_be_kind_of DateTime
    subject.released_at.must_equal DateTime.parse("30/03/1981")
    subject.hit.length.must_equal 312
    subject.hit.good.must_equal nil
    subject.band.label.value.must_equal "9999.999999.99" # coercion happened once.
  end
end


class CoercionWithoutSkipSetterTest < MiniTest::Spec
  class Irreversible < Virtus::Attribute
    def coerce(value)
      value*2
    end
  end

  class Twin < Disposable::Twin
    feature Coercion
    property :id, type: Irreversible
  end

  it do
    twin = Twin.new(OpenStruct.new(id: "1"))
    twin.id.must_equal "11" # coercion happens in Setup.
    twin.id = "2"
    twin.id.must_equal "22"
  end
end