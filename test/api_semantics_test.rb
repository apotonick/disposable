require "test_helper"
require "disposable/twin"
require "ostruct"

module Model
  Song  = Struct.new(:id, :title)
  Album = Struct.new(:id, :name, :songs)
end

class Skip < OpenStruct
end
class Remove < Skip
end

class AlbumDecorator < Representable::Decorator
  include Representable::Hash

  collection :songs,
    instance:   lambda { |hash, *options|
      if hash["_action"] == "remove"
        Remove.new(hash) # the deserializer will assign {id: 2, title: "Sunlit Nights"}.
      else
        if songs.collect { |s| s.id.to_s }.include?(hash["id"].to_s) and hash["_action"] != "remove"
          Skip.new(hash)
        else
          Model::Song.new
        end
      end
      },
    # skip_parse: lambda { |fragment, *args|
    #   puts "sss #{fragment.inspect}... #{songs.collect { |s| s.id.to_s }.inspect}"
    #   songs.collect { |s| s.id.to_s }.include?(fragment["id"].to_s) }, # read-only existing.

    setter:     lambda { |value, options|
      remove_items  = value.find_all { |i| i.instance_of?(Remove) }
      # add_items     = value.find_all { |i| i.instance_of?(Add) }.collect(&:model)
      add_items     = value - remove_items

      skip_items  = value.find_all { |i| i.instance_of?(Skip) }
      # add_items     = value.find_all { |i| i.instance_of?(Add) }.collect(&:model)
      add_items     = add_items - skip_items

      self.songs += add_items
      self.songs -= remove_items.collect { |i| songs.find { |s| s.id.to_s == i.id.to_s } }
     } do # add new to existing collection.

      # only add new songs
      property :title
  end
end

album = Model::Album.new(1, "And So I Watch You From Afar", [Model::Song.new(2, "Solidarity"), Model::Song.new(0, "Tale That Wasn't Right")])

decorator = AlbumDecorator.new(album)
decorator.from_hash({"songs" => [
  {"id" => 2, "title" => "Solidarity, but wrong title"}, # skip
  {"id" => 0, "title" => "Tale That Wasn't Right, but wrong title", "_action" => "remove"}, # delete
  {"id" => 4, "title" => "Capture Castles"} # add, default.
]})

puts decorator.represented.songs.inspect

# [
#   {"_action": "add"},
#   {"id": 2, "_action": "remove"}
# ]