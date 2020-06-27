# frozen_string_literal: true

require 'test_helper'
# require 'reform/form/coercion'

class ChangedWithSetupTest < MiniTest::Spec
  module Model
    Song  = Struct.new(:title, :length, :composer)
    Album = Struct.new(:name, :songs, :artist)
    Artist = Struct.new(:name)
  end

  module Twin
    class Album < Disposable::Twin
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
        property :name
      end
    end
  end

  let(:song)     { Model::Song.new('Broken') }
  let(:composer) { Model::Artist.new(2) }
  let(:song_with_composer) { Model::Song.new('Broken', 246, composer) }
  let(:artist)   { Model::Artist.new('Randy') }
  let(:album)    { Model::Album.new('The Rest Is Silence', [song, song_with_composer], artist) }
  let(:twin)     { Twin::Album.new(album) }

  # setup: changed? is always false
  it do
    _(twin.changed?(:name)).must_equal false
    _(twin.changed?).must_equal false

    _(twin.songs[0].changed?).must_equal false
    _(twin.songs[0].changed?(:title)).must_equal false
    _(twin.songs[1].changed?).must_equal false
    _(twin.songs[1].changed?(:title)).must_equal false

    _(twin.songs[1].composer.changed?(:name)).must_equal false
    _(twin.songs[1].composer.changed?).must_equal false

    _(twin.artist.changed?(:name)).must_equal false
    _(twin.artist.changed?).must_equal false
  end

  # only when a property is assigned, it's changed.
  it do
    twin.name = 'Out Of Bounds'
    twin.songs[0].title = 'I Have Seen'
    twin.songs[1].title = 'In A Rhyme'
    twin.songs[1].composer.name = 'Ingemar Jansson & Mikael Danielsson'
    twin.artist.name = 'No Fun At All'

    _(twin.changed?(:name)).must_equal true
    _(twin.changed?).must_equal true

    _(twin.songs[0].changed?).must_equal true
    _(twin.songs[0].changed?(:title)).must_equal true
    _(twin.songs[1].changed?).must_equal true
    _(twin.songs[1].changed?(:title)).must_equal true

    _(twin.songs[1].composer.changed?(:name)).must_equal true
    _(twin.songs[1].composer.changed?).must_equal true

    _(twin.artist.changed?(:name)).must_equal true
    _(twin.artist.changed?).must_equal true

    # you can also ask for nested twins by name.
    _(twin.changed?(:songs)).must_equal true
    _(twin.songs[0].changed?(:composer)).must_equal false
    _(twin.songs[1].changed?(:composer)).must_equal true
    _(twin.changed?(:artist)).must_equal true
  end

  # nested changes should propagate up.
  it do
    _(twin.changed?).must_equal false

    twin.songs[1].composer.name = 'Nofx'

    _(twin.changed?).must_equal true

    assert twin.songs.changed?
    _(twin.songs[1].changed?).must_equal true
    _(twin.songs[0].changed?).must_equal false

    _(twin.artist.changed?).must_equal false
  end

  # setting identical value doesn't change.
  it do
    twin.name = 'The Rest Is Silence'
    _(twin.changed?).must_equal false
  end
end

require 'disposable/twin/coercion'
class ChangedWithCoercionTest < MiniTest::Spec
  Song = Struct.new(:released)

  class SongTwin < Disposable::Twin
    include Changed
    include Coercion

    property :released, type: Types::Params::Bool | Types::Params::Nil
  end

  it do
    twin = SongTwin.new(Song.new)
    _(twin.changed?(:released)).must_equal false
    twin.released = 'true'
    _(twin.released).must_equal true
    _(twin.changed?(:released)).must_equal true
  end

  it do
    twin = SongTwin.new(Song.new(true))
    _(twin.changed?(:released)).must_equal false
    twin.released = 'true' # it coerces, then assigns, then compares, which makes this NOT changed.
    _(twin.changed?(:released)).must_equal false
    twin.released = 'false'
    _(twin.changed?(:released)).must_equal true
  end
end
