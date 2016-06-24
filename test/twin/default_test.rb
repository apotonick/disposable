require "test_helper"

class DefaultTest < Minitest::Spec
  Song     = Struct.new(:title, :genre, :composer)
  Composer = Struct.new(:name)

  class Twin < Disposable::Twin
    feature Default

    property :title, default: "Medio-Core"
    property :genre, default: -> { "Punk Rock #{model.class}" }
    property :composer, default: Composer.new do
      property :name, default: "NOFX"
    end
  end

  # all given.
  it do
    twin = Twin.new(Song.new("Anarchy Camp", "Punk", Composer.new("Nofx")))
    twin.title.must_equal "Anarchy Camp"
    twin.genre.must_equal "Punk"
    twin.composer.name.must_equal "Nofx"
  end

  # defaults, please.
  it do
    twin = Twin.new(Song.new)
    twin.title.must_equal "Medio-Core"
    twin.composer.name.must_equal "NOFX"
    twin.genre.must_equal "Punk Rock DefaultTest::Song"
  end

  # false value is not defaulted.
  it do
    twin = Twin.new(Song.new(false))
    twin.title.must_equal false
  end

  describe "inheritance" do
    class SuperTwin < Disposable::Twin
      feature Default
      property :name, default: "n/a"
    end
    class MegaTwin < SuperTwin
    end

    it { MegaTwin.new(Composer.new).name.must_equal "n/a" }
  end
end

class DefaultAndVirtualTest < Minitest::Spec
  class Twin < Disposable::Twin
    feature Default
    feature Changed

    property :title, default: "0", virtual: true
  end

  it do
    twin = Twin.new(Object.new)
    twin.title.must_equal "0"
    # twin.changed.must_equal []
  end
end

