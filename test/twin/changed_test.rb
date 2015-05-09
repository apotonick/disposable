require 'test_helper'
# require 'reform/form/coercion'

class ChangedWithSetupTest < MiniTest::Spec
  module Model
    Song  = Struct.new(:title, :length, :composer)
    Album = Struct.new(:name, :songs, :artist)
    Artist = Struct.new(:name)
  end

  require "disposable/twin/changed"
  module Twin
    class Album < Disposable::Twin
      feature Setup
      feature Changed
      # include Coercion
      property :name

      collection :songs do
        property :title
        property :length, type: Integer

        property :composer do
          property :name
        end
      end

      property :artist do
        include Setup
        property :name
      end
    end
  end

  # setup: changed? is always false
  let (:song)     { Model::Song.new("Broken") }
  let (:composer) { Model::Artist.new(2) }
  let (:song_with_composer) { Model::Song.new("Broken", 246, composer) }
  let (:artist)   { Model::Artist.new("Randy") }
  let (:album)    { Model::Album.new("The Rest Is Silence", [song, song_with_composer], artist) }

  it do
    twin = Twin::Album.new(album)


    twin.songs[0].changed.must_equal( {})

    twin.changed?(:name).must_equal false
    twin.changed?.must_equal false

    twin.songs[0].changed?.must_equal false
    twin.songs[0].changed?(:title).must_equal false
    twin.songs[1].changed?.must_equal false
    twin.songs[1].changed?(:title).must_equal false

    twin.songs[1].composer.changed?(:name).must_equal false
    twin.songs[1].composer.changed?.must_equal false

    twin.artist.changed?(:name).must_equal false
    twin.artist.changed?.must_equal false
  end


  # describe "#validate" do
  #   before { form.validate(
  #     "title" => "Five", # changed.
  #     "hit"   => {"title"  => "The Ripper", # same, but overridden.
  #                 "length" => "9"}, # gets coerced, then compared, so not changed.
  #     "band"  => {"label" => {"name" => "Shrapnel Records"}} # only label.name changes.
  #   ) }

  #   it { form.changed?(:title).must_equal true }

  #   # it { form.changed?(:hit).must_equal false }

  #   # overridden with same value is no change.
  #   it { form.hit.changed?(:title).must_equal false }
  #   # coerced value is identical to form's => not changed.
  #   it { form.hit.changed?(:length).must_equal false }

  #   # it { form.changed?(:band).must_equal true }
  #   # it { form.band.changed?(:label).must_equal true }
  #   it { form.band.label.changed?(:name).must_equal true }

  #   # not present key/value in #validate is no change.
  #   it { form.band.label.changed?(:location).must_equal false }
  #   # TODO: parent form changed when child has changed!
  # end
end