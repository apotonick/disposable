require 'test_helper'


require "test_helper"

class SaveTest < MiniTest::Spec
  module Model
    Song  = Struct.new(:title, :composer)
    Album = Struct.new(:name, :songs, :artist)
    Artist = Struct.new(:name)
  end


  module Twin
    class Album < Disposable::Twin
      feature Setup
      feature Sync
      feature Save

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


  module Saveable
    def save
      @saved = true
    end

    def saved?
      @saved
    end
  end


  let (:song) { Model::Song.new().extend(Saveable) }
  let (:composer) { Model::Artist.new(nil).extend(Saveable) }
  let (:song_with_composer) { Model::Song.new(nil, composer).extend(Saveable) }
  let (:artist) { Model::Artist.new(nil).extend(Saveable) }


  let (:album) { Model::Album.new(nil, [song, song_with_composer], artist).extend(Saveable) }

  # with populated model.
  it do
    twin = Twin::Album.new(album)

    # this usually happens in Contract::Validate or in from_* in a representer
    twin.name = "Live And Dangerous"
    twin.songs[0].title = "Southbound"
    twin.songs[1].title = "The Boys Are Back In Town"
    twin.songs[1].composer.name = "Lynott"
    twin.artist.name = "Thin Lizzy"


    twin.save

    # sync happened.
    album.name.must_equal "Live And Dangerous"
    album.songs[0].must_be_instance_of Model::Song
    album.songs[1].must_be_instance_of Model::Song
    album.songs[0].title.must_equal "Southbound"
    album.songs[1].title.must_equal "The Boys Are Back In Town"
    album.songs[1].composer.must_be_instance_of Model::Artist
    album.songs[1].composer.name.must_equal "Lynott"
    album.artist.must_be_instance_of Model::Artist
    album.artist.name.must_equal "Thin Lizzy"

    # saved?
    album.saved?.must_equal true
    album.songs[0].saved?.must_equal true
    album.songs[1].saved?.must_equal true
    album.songs[1].composer.saved?.must_equal true
    album.artist.saved?.must_equal true
  end






  module Twin
    class AlbumWithSaveFalse < Disposable::Twin
      feature Setup
      feature Sync
      feature Save

      property :name

      collection :songs, save: false do
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

  # with save: false.
  it do
    twin = Twin::AlbumWithSaveFalse.new(album)

    # this usually happens in Contract::Validate or in from_* in a representer
    twin.name = "Live And Dangerous"
    twin.songs[0].title = "Southbound"
    twin.songs[1].title = "The Boys Are Back In Town"
    twin.songs[1].composer.name = "Lynott"
    twin.artist.name = "Thin Lizzy"


    twin.save

    # sync happened.
    album.name.must_equal "Live And Dangerous"
    album.songs[0].must_be_instance_of Model::Song
    album.songs[1].must_be_instance_of Model::Song
    album.songs[0].title.must_equal "Southbound"
    album.songs[1].title.must_equal "The Boys Are Back In Town"
    album.songs[1].composer.must_be_instance_of Model::Artist
    album.songs[1].composer.name.must_equal "Lynott"
    album.artist.must_be_instance_of Model::Artist
    album.artist.name.must_equal "Thin Lizzy"

    # saved?
    album.saved?.must_equal true
    album.songs[0].saved?.must_equal nil
    album.songs[1].saved?.must_equal nil
    album.songs[1].composer.saved?.must_equal nil # doesn't get saved.
    album.artist.saved?.must_equal true
  end
end


# TODO: with block

#   # #save returns result (this goes into disposable soon).
#   it { subject.save.must_equal true }
#   it do
#     album.instance_eval { def save; false; end }
#     subject.save.must_equal false
#   end
# end


# class SaveWithDynamicOptionsTest < MiniTest::Spec
#   Song = Struct.new(:id, :title, :length) do
#     include Saveable
#   end

#   class SongForm < Reform::Form
#     property :title#, save: false
#     property :length, virtual: true
#   end

#   let (:song) { Song.new }
#   let (:form) { SongForm.new(song) }

#   # we have access to original input value and outside parameters.
#   it "xxx" do
#     form.validate("title" => "A Poor Man's Memory", "length" => 10)
#     length_seconds = 120
#     form.save(length: lambda { |value, options| form.model.id = "#{value}: #{length_seconds}" })

#     song.title.must_equal "A Poor Man's Memory"
#     song.length.must_equal nil
#     song.id.must_equal "10: 120"
#   end
# end