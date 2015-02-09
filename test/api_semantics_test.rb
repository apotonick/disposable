require "test_helper"
require "disposable/twin"
require "ostruct"

module Model
  Song  = Struct.new(:id, :title)
  Album = Struct.new(:id, :name, :songs)
end

class Skip < OpenStruct
end

class AlbumDecorator < Representable::Decorator
  include Representable::Hash

  collection :songs,
    instance: lambda { |hash, *options|
      if hash["id"] == 2 # existings are read-only.
        Skip.new
      else
        Model::Song.new
      end
    },

    setter: lambda { |value, options| self.songs += value.reject { |i| i.is_a?(Skip) } } do

      # only add new songs
      property :title
  end
end

album = Model::Album.new(1, "And So I Watch You From Afar", [Model::Song.new(2, "Solidarity")])

decorator = AlbumDecorator.new(album)
decorator.from_hash({"songs" => [{"id" => 2, "title" => "Solidarity, but wrong title"}, {"id" => 4, "title" => "Capture Castles"}]})

# create new song, replace old list (default).
puts decorator.represented.songs.inspect