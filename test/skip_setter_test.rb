require "test_helper"

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
    twin = AlbumTwin.new(Album.new("Wild Frontier", Artist.new("Gary Moore")))

    twin.title.must_equal "Wild Frontier"
    twin.artist.name.must_equal "Gary Moore"
  end
end