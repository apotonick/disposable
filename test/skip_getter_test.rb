require "test_helper"

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
    album = Album.new("Wild Frontier", Artist.new("Gary Moore"))
    twin  = AlbumTwin.new(album)

    twin.title.must_equal "reitnorF dliW"
    twin.artist.name.must_equal "GARY MOORE"

    twin.sync # does NOT call getter.

    album.title.must_equal "Wild Frontier"
    album.artist.name.must_equal "Gary Moore"
  end
end