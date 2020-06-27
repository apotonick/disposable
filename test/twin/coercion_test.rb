# frozen_string_literal: true

require 'test_helper'

require 'disposable/twin/coercion'

class CoercionTest < MiniTest::Spec
  class TwinWithSkipSetter < Disposable::Twin
    feature Coercion
    feature Setup::SkipSetter

    property :id
    property :released_at, type: Types::Params::DateTime

    property :hit do
      property :length, type: Types::Params::Integer
      property :good,   type: Types::Params::Bool
    end

    property :band do
      property :label do
        property :value, type: Types::Coercible::Float
      end
    end
  end

  describe 'with Setup::SkipSetter' do
    subject do
      TwinWithSkipSetter.new(album)
    end

    let(:album) do
      OpenStruct.new(
        id: 1,
        released_at: '31/03/1981',
        hit: OpenStruct.new(length: '312'),
        band: OpenStruct.new(label: OpenStruct.new(value: '9999.99'))
      )
    end

    it 'NOT coerce values in setup' do
      _(subject.released_at).must_equal '31/03/1981'
      _(subject.hit.length).must_equal '312'
      _(subject.band.label.value).must_equal '9999.99'
    end

    it 'coerce values when using a setter' do
      subject.id = Object
      subject.released_at = '30/03/1981'
      subject.hit.length = '312'
      subject.band.label.value = '9999.99'

      _(subject.released_at).must_be_kind_of DateTime
      _(subject.released_at).must_equal DateTime.parse('30/03/1981')
      _(subject.hit.length).must_equal 312
      _(subject.hit.good).must_be_nil
      _(subject.band.label.value).must_equal 9999.99
    end
  end

  class TwinWithoutSkipSetter < Disposable::Twin
    feature Coercion
    property :id, type: Types::Params::Integer
  end

  describe 'without Setup::SkipSetter' do
    subject do
      TwinWithoutSkipSetter.new(OpenStruct.new(id: '1'))
    end

    it 'coerce values in setup and when using a setter' do
      _(subject.id).must_equal 1
      subject.id = '2'
      _(subject.id).must_equal 2
    end
  end
end

# this converts "" to nil and then breaks because it's strict.
# Types::Strict::String.constructor(Dry::Types::Params.method(:to_nil))

class CoercionTypingTest < MiniTest::Spec
  class Song < Disposable::Twin
    include Coercion
    include Setup::SkipSetter

    # property :title, type: Dry::Types::Strict::String.constructor(Dry::Types::Params.method(:to_nil))
    property :title, type: Types::Strict::String.optional # this is the behavior of the "DB" data twin. this is NOT the form.

    # property :name, type: Types::Params::String
  end

  it do
    twin = Song.new(Struct.new(:title, :name).new)

    # with type: Dry::Types::Strict::String
    # assert_raises(Dry::Types::ConstraintError) { twin.title = nil }
    twin.title = nil
    _(twin.title).must_be_nil

    twin.title = 'Yo'
    _(twin.title).must_equal 'Yo'

    twin.title = ''
    _(twin.title).must_equal ''

    assert_raises(Dry::Types::ConstraintError) { twin.title = :bla }
    assert_raises(Dry::Types::ConstraintError) { twin.title = 1 }
  end

  # Form
  class Form < Disposable::Twin
    include Coercion
    include Setup::SkipSetter

    # property :title, type: Dry::Types::Strict::String.constructor(Dry::Types::Params.method(:to_nil))

    property :title, type: Types::Params::Nil | Types::Strict::String # this is the behavior of the "DB" data twin. this is NOT the form.

    # property :name, type: Types::Params::String

    property :enabled, type: Types::Params::Bool
    # property :enabled, Bool.constructor(:trim!)
  end
  it do
    twin = Form.new(Struct.new(:title, :enabled).new)

    # assert_raises(Dry::Types::ConstraintError) { twin.title = nil } # in form, we either have a blank string or the key's not present at all.
    twin.title = nil
    _(twin.title).must_be_nil

    twin.title = '' # nilify blank strings
    _(twin.title).must_be_nil

    twin.title = 'Yo'
    _(twin.title).must_equal 'Yo'

    # twin.enabled = " TRUE"
    # twin.enabled.must_equal true
  end
end

# def title=(String value) # allow obj.title = "bla"
# def title=(Nil)          # allow obj.title = nil

# active = " TRUE HACK"
# how to test/validate if active is boolean?
