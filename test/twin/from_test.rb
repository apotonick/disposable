# require 'test_helper'

# class FromTest < MiniTest::Spec
#   module Model
#     Song  = Struct.new(:title, :composer)
#     Album = Struct.new(:name, :songs, :artist)
#     Artist = Struct.new(:name)
#   end


#   module Twin
#     class Album < Disposable::Twin
#       feature Setup
#       feature Sync
#       feature Save

#       property :full_name, from: :name

#       # collection :songs do
#       #   property :title

#       #   property :composer do
#       #     property :name
#       #   end
#       # end

#       # property :artist do
#       #   property :name
#       # end
#     end
#   end


#   let (:song) { Model::Song.new() }
#   let (:composer) { Model::Artist.new(nil) }
#   let (:song_with_composer) { Model::Song.new(nil, composer) }
#   let (:artist) { Model::Artist.new(nil) }


#   let (:album) { Model::Album.new("The Sufferer And The Witness", [song, song_with_composer], artist) }

#   it do
#     twin = Twin::Album.new(album)

#     twin.full_name.must_equal "The Sufferer And The Witness"
#   end
# end