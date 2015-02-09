require "test_helper"
require "disposable/twin"

module Model
  Song  = Struct.new(:id, :title)
  Album = Struct.new(:id, :name, :songs)
end

class AlbumDecorator < Representable::Decorator
  include Representable::Hash

  collection :songs,
    instance: lambda { |hash, *options| Model::Song.new },

    setter: lambda { |value, options| self.songs += value } do

      # only add new songs
      property :title
  end
end

album = Model::Album.new(1, "And So I Watch You From Afar", [Model::Song.new(2, "Solidarity")])

decorator = AlbumDecorator.new(album)
decorator.from_hash({"songs" => [{"id" => 4, "title" => "Capture Castles"}]})

# create new song, replace old list (default).
puts decorator.represented.songs.inspect