require 'test_helper'

class FeatureTest < MiniTest::Spec
  Song  = Struct.new(:title, :album, :composer)
  Album = Struct.new(:name, :songs, :artist)
  Artist = Struct.new(:name)

  module Date
    def date
      "May 16"
    end
  end

  module Instrument
    def instrument
      "Violins"
    end
  end

  class AlbumForm < Disposable::Twin
    include Setup
    feature Date
    property :name

    collection :songs do
      include Setup
      property :title

      property :composer do
        include Setup
        feature Instrument
        property :name
      end
    end

    property :artist do
      include Setup
      property :name
    end
  end

  let (:song)               { Song.new("Broken") }
  let (:song_with_composer) { Song.new("Resist Stance", nil, composer) }
  let (:composer)           { Artist.new("Greg Graffin") }
  let (:artist)             { Artist.new("Bad Religion") }
  let (:album)              { Album.new("The Dissent Of Man", [song, song_with_composer], artist) }

  let (:form) { AlbumForm.new(album) }

  it do
    form.date.must_equal "May 16"
    form.artist.date.must_equal "May 16"
    form.songs[0].date.must_equal "May 16"
    form.songs[1].date.must_equal "May 16"
    form.songs[1].composer.date.must_equal "May 16"
    form.songs[1].wont_be_kind_of(Instrument)
    form.songs[1].composer.must_be_kind_of(Instrument)
    form.songs[1].composer.instrument.must_equal "Violins"
    form.artist.date.must_equal "May 16"
  end
end