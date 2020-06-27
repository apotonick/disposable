# frozen_string_literal: true

require 'test_helper'

class DefaultTest < Minitest::Spec
  Song     = Struct.new(:title, :new_album, :published, :genre, :composer)
  Composer = Struct.new(:name)

  class Twin < Disposable::Twin
    feature Default

    property :title, default: 'Medio-Core'
    property :genre, default: -> { "Punk Rock #{model.class}" }
    property :composer, default: Composer.new do
      property :name, default: 'NOFX'
    end
    property :published, default: false
    property :new_album, default: true
  end

  # all given.
  it do
    twin = Twin.new(Song.new('Anarchy Camp', false, true, 'Punk', Composer.new('Nofx')))
    _(twin.title).must_equal 'Anarchy Camp'
    _(twin.genre).must_equal 'Punk'
    _(twin.composer.name).must_equal 'Nofx'
    _(twin.published).must_equal true
    _(twin.new_album).must_equal false
  end

  # defaults, please.
  it do
    twin = Twin.new(Song.new)
    _(twin.title).must_equal 'Medio-Core'
    _(twin.composer.name).must_equal 'NOFX'
    _(twin.genre).must_equal 'Punk Rock DefaultTest::Song'
    _(twin.published).must_equal false
    _(twin.new_album).must_equal true
  end

  # false value is not defaulted.
  it do
    twin = Twin.new(Song.new(false, false))
    _(twin.title).must_equal false
    _(twin.new_album).must_equal false
  end

  describe 'inheritance' do
    class SuperTwin < Disposable::Twin
      feature Default
      property :name, default: 'n/a'
    end
    class MegaTwin < SuperTwin
    end

    it { _(MegaTwin.new(Composer.new).name).must_equal 'n/a' }
  end
end

class DefaultAndVirtualTest < Minitest::Spec
  class Twin < Disposable::Twin
    feature Default
    feature Changed

    property :title, default: '0', virtual: true
  end

  it do
    twin = Twin.new(Object.new)
    _(twin.title).must_equal '0'
    # twin.changed.must_equal []
  end
end
