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


require "disposable/twin/struct"
class DefaultWithStructTest < Minitest::Spec
  Song     = Struct.new(:settings)

  class Twin < Disposable::Twin
    feature Default
    feature Sync

    property :settings, default: Hash.new do
      include Struct

      property :enabled, default: "yes"
      property :roles, default: Hash.new do
        include Struct
        property :admin, default: "maybe"
      end
    end
  end

  # all given.
  it do
    twin = Twin.new(Song.new({enabled: true, roles: {admin: false}}))
    twin.settings.enabled.must_equal true
    twin.settings.roles.admin.must_equal false
  end

  # defaults, please.
  it do
    song = Song.new
    twin = Twin.new(song)
    twin.settings.enabled.must_equal "yes"
    twin.settings.roles.admin.must_equal "maybe"

    twin.sync

    song.settings.must_equal({"enabled"=>"yes", "roles"=>{"admin"=>"maybe"}})
  end
end
