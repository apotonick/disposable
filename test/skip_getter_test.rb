# frozen_string_literal: true

require 'test_helper'

class SkipGetterTest < MiniTest::Spec
  Album  = Struct.new(:title, :artist)
  Artist = Struct.new(:name)

  class AlbumTwin < Disposable::Twin
    feature Sync
    feature Sync::SkipGetter

    property :title
    property :artist do
      property :name

      def name
        super.upcase
      end
    end

    def title
      super.reverse
    end
  end

  it do
    album = Album.new('Wild Frontier', Artist.new('Gary Moore'))
    twin  = AlbumTwin.new(album)

    _(twin.title).must_equal 'reitnorF dliW'
    _(twin.artist.name).must_equal 'GARY MOORE'

    twin.sync # does NOT call getter.

    _(album.title).must_equal 'Wild Frontier'
    _(album.artist.name).must_equal 'Gary Moore'

    # nested hash.
    nested_hash = nil
    twin.sync do |hash|
      nested_hash = hash
    end
    _(nested_hash).must_equal({ 'title' => 'Wild Frontier', 'artist' => { 'name' => 'Gary Moore' } })
  end
end

class SkipSetterTest < MiniTest::Spec
  Album  = Struct.new(:title, :artist)
  Artist = Struct.new(:name)

  class AlbumTwin < Disposable::Twin
    feature Setup::SkipSetter

    property :title
    property :artist do
      property :name

      def name=(v)
        super(v.upcase)
      end
    end

    def title=(v)
      super(v.reverse)
    end
  end

  it do
    twin = AlbumTwin.new(Album.new('Wild Frontier', Artist.new('Gary Moore')))

    _(twin.title).must_equal 'Wild Frontier'
    _(twin.artist.name).must_equal 'Gary Moore'
  end
end

class SkipGetterAndSetterWithChangedTest < MiniTest::Spec
  Album  = Struct.new(:title, :artist)
  Artist = Struct.new(:name)

  class AlbumTwin < Disposable::Twin
    feature Sync
    feature Sync::SkipGetter
    feature Setup::SkipSetter
    feature Changed

    property :title
    property :artist do
      property :name

      def name
        super.upcase
      end

      def name=(v)
        super v.chop
      end
    end

    def title
      super.reverse
    end

    def title=(v)
      super v.reverse
    end
  end

  it do
    album = Album.new('Wild Frontier', Artist.new('Gary Moore'))
    twin  = AlbumTwin.new(album) # does not call getter (Changed).

    _(twin.title).must_equal 'reitnorF dliW'
    _(twin.artist.name).must_equal 'GARY MOORE'

    _(twin.changed?).must_equal false
    _(twin.artist.changed?).must_equal false

    twin.title = 'Self-Entitled'
    twin.artist.name = 'Nofx'

    twin.sync # does NOT call getter.

    _(album.title).must_equal 'deltitnE-fleS'
    _(album.artist.name).must_equal 'Nof'
  end
end
