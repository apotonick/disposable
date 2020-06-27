# frozen_string_literal: true

require 'test_helper'

class SkipUnchangedTest < MiniTest::Spec
  module Model
    Song  = Struct.new(:title, :composer)
    Album = Struct.new(:name, :songs, :artist)
    Artist = Struct.new(:name)
  end

  module Twin
    class Album < Disposable::Twin
      feature Setup
      feature Sync
      feature Sync::SkipUnchanged

      property :name

      collection :songs do
        property :title

        property :composer do
          property :name
        end
      end

      property :artist do
        property :name
      end
    end
  end

  let(:song) { Model::Song.new }
  let(:composer) { Model::Artist.new(nil) }
  let(:song_with_composer) { Model::Song.new('American Jesus', composer) }
  let(:artist) { Model::Artist.new('Bad Religion') }

  let(:album) { Model::Album.new('30 Years Live', [song, song_with_composer], artist) }

  it do
    twin = Twin::Album.new(album)

    twin.songs[1].composer.name = 'Greg Graffin'
    twin.songs[0].title = 'Resist Stance'

    # raises exceptions when setters are called.
    album.instance_eval do
      def name=
        raise
      end
    end
    artist.instance_eval do
      def name=
        raise
      end
    end
    song_with_composer.instance_eval do
      def title=
        raise
      end
    end

    twin.sync

    # unchanged, and no exception raised.
    _(album.name).must_equal '30 Years Live'
    _(song_with_composer.title).must_equal 'American Jesus'
    _(artist.name).must_equal 'Bad Religion'

    # this actually got synced.
    _(song_with_composer.composer.name).must_equal 'Greg Graffin' # was nil.
    _(song.title).must_equal 'Resist Stance' # was nil.
  end
end
