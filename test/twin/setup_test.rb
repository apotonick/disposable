# frozen_string_literal: true

require 'test_helper'

class TwinSetupTest < MiniTest::Spec
  module Model
    Song  = Struct.new(:id, :title, :album, :composer)
    Album = Struct.new(:id, :name, :songs, :artist)
    Artist = Struct.new(:id)
  end

  module Twin
    class Artist < Disposable::Twin
      property :id

      include Setup
    end

    class Song < Disposable::Twin
      property :id
      property :composer, twin: Twin::Artist

      include Setup
    end

    class Album < Disposable::Twin
      property :id
      property :name
      collection :songs, twin: Twin::Song
      property :artist, twin: Twin::Artist

      include Setup
    end
  end

  let(:song) { Model::Song.new(1, 'Broken', nil) }
  let(:composer) { Model::Artist.new(2) }
  let(:song_with_composer) { Model::Song.new(1, 'Broken', nil, composer) }
  let(:artist) { Model::Artist.new(9) }

  describe 'with songs: [song, song{composer}]' do
    let(:album) { Model::Album.new(1, 'The Rest Is Silence', [song, song_with_composer], artist) }

    it do
      twin = Twin::Album.new(album)

      _(twin.songs.size).must_equal 2
      _(twin.songs).must_be_instance_of Disposable::Twin::Collection

      _(twin.songs[0]).must_be_instance_of Twin::Song
      _(twin.songs[0].id).must_equal 1

      _(twin.songs[1]).must_be_instance_of Twin::Song
      _(twin.songs[1].id).must_equal 1
      _(twin.songs[1].composer).must_be_instance_of Twin::Artist
      _(twin.songs[1].composer.id).must_equal 2
    end
  end

  describe 'with songs: [] and artist: nil' do
    let(:album) { Model::Album.new(1, 'The Rest Is Silence', [], nil) }

    it do
      twin = Twin::Album.new(album)

      _(twin.songs.size).must_equal 0
      _(twin.songs).must_be_instance_of Disposable::Twin::Collection
    end
  end

  # DISCUSS: do we need to cover that (songs: nil in model)?
  # describe "with non-existent :songs" do
  #   let (:album) { Model::Album.new(1, "The Rest Is Silence", nil) }

  #   it do
  #     twin = Twin::Album.new(album)

  #     twin.songs.size.must_equal 0
  #     twin.songs.must_be_instance_of Disposable::Twin::Collection
  #   end
  # end
end

# test inline twin building and setup.
class TwinSetupWithInlineTwinsTest < MiniTest::Spec
  module Model
    Song  = Struct.new(:id, :composer)
    Album = Struct.new(:id, :name, :songs, :artist)
    Artist = Struct.new(:id)
  end

  class AlbumForm < Disposable::Twin
    feature Setup

    property :id
    property :name

    collection :songs do # default_inline_class: Disposable::Twin
      property :id

      property :composer do
        property :id
      end
    end

    property :artist do
      property :id
    end
  end

  let(:song) { Model::Song.new(1) }
  let(:composer) { Model::Artist.new(2) }
  let(:song_with_composer) { Model::Song.new(3, composer) }
  let(:artist) { Model::Artist.new(9) }
  let(:album) { Model::Album.new(0, 'Toto Live', [song, song_with_composer], artist) }

  it do
    twin = AlbumForm.new(album)
    # pp twin

    _(twin.id).must_equal 0
    _(twin.name).must_equal 'Toto Live'

    _(twin.artist).must_be_kind_of Disposable::Twin
    _(twin.artist.id).must_equal 9

    _(twin.songs).must_be_instance_of Disposable::Twin::Collection

    # nil nested objects work (no composer)
    _(twin.songs[0]).must_be_kind_of Disposable::Twin
    _(twin.songs[0].id).must_equal 1

    _(twin.songs[1]).must_be_kind_of Disposable::Twin
    _(twin.songs[1].id).must_equal 3

    _(twin.songs[1].composer).must_be_kind_of Disposable::Twin
    _(twin.songs[1].composer.id).must_equal 2
  end
end

# Twin.new(model, is_online: true)
class TwinWithVirtualSetupTest < MiniTest::Spec
  Song = Struct.new(:id)

  class AlbumTwin < Disposable::Twin
    property :id
    property :is_online, readable: false, writeable: false
  end

  it do
    twin = AlbumTwin.new(Song.new(1), is_online: true)
    _(twin.id).must_equal 1
    _(twin.is_online).must_equal true
  end
end
