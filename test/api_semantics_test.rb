require "test_helper"
require "disposable/twin"
require "ostruct"

module Model
  Song  = Struct.new(:id, :title)
  Album = Struct.new(:id, :name, :songs)
end

module Representable
  class Semantics
    class Skip < OpenStruct
    end
    class Remove < Skip
    end

    # Per parsed collection item, mark the to-be-populated model for removal, skipping or adding.
    # This code is called right before #from_format is called on the model.
    # Semantical behavior is inferred from the fragment making this code document- and format-specific.
    class Instance
      include Uber::Callable

      def call(model, fragment, index, options)
        if fragment["_action"] == "remove"
          Remove.new(fragment) # the deserializer will assign {id: 2, title: "Sunlit Nights"}.
        else
          # the if is an optional feature!
          if model.songs.collect { |s| s.id.to_s }.include?(fragment["id"].to_s) and fragment["_action"] != "remove"
            Skip.new(fragment)
          else
            Model::Song.new
          end
        end
      end
    end

    class Setter
      include Uber::Callable

      def call(model, values, options)
        remove_items  = values.find_all { |i| i.instance_of?(Representable::Semantics::Remove) }
        # add_items     = values.find_all { |i| i.instance_of?(Add) }.collect(&:model)
        add_items     = values - remove_items

        skip_items  = values.find_all { |i| i.instance_of?(Representable::Semantics::Skip) }
        # add_items     = values.find_all { |i| i.instance_of?(Add) }.collect(&:model)
        add_items     = add_items - skip_items

        model.songs += add_items
        model.songs -= remove_items.collect { |i| model.songs.find { |s| s.id.to_s == i.id.to_s } }
      end
    end
  end
end

class AlbumDecorator < Representable::Decorator
  include Representable::Hash

  collection :songs,
    instance: Representable::Semantics::Instance.new,

      pass_options: true,
    # skip_parse: lambda { |fragment, *args|
    #   puts "sss #{fragment.inspect}... #{songs.collect { |s| s.id.to_s }.inspect}"
    #   songs.collect { |s| s.id.to_s }.include?(fragment["id"].to_s) }, # read-only existing.

    setter: Representable::Semantics::Setter.new do # add new to existing collection.

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