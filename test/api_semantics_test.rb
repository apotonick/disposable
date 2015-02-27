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
        semantics = options.binding[:semantics]

        if fragment["_action"] == "remove" # TODO: check if feature enabled.
          Remove.new(fragment) # the deserializer will assign {id: 2, title: "Sunlit Nights"}.
        else
          # the if is an optional feature!
          if semantics.include?(:skip_existing)
            if model.songs.collect { |s| s.id.to_s }.include?(fragment["id"].to_s) #and fragment["_action"] != "remove"

              puts "¬¬¬¬¬¬¬ skipping #{fragment}"
              return Skip.new(fragment)

            else
              Model::Song.new
            end

          elsif semantics.include?(:update_existing)
            puts "yooo #{model.songs.inspect}"
            if res= model.songs.find { |s| s.id.to_s == fragment["id"].to_s }
              puts "$$$ #{res}"

              # what if item not found by id?


              return res
            else
              Model::Song.new
            end
          else
            Model::Song.new
          end
        end
      end
    end

    class Setter
      include Uber::Callable

      def call(model, values, options)
puts "Setter: #{values.inspect}"

        remove_items  = values.find_all { |i| i.instance_of?(Representable::Semantics::Remove) }
        # add_items     = values.find_all { |i| i.instance_of?(Add) }.collect(&:model)
        add_items     = values - remove_items

        skip_items  = values.find_all { |i| i.instance_of?(Representable::Semantics::Skip) }
        # add_items     = values.find_all { |i| i.instance_of?(Add) }.collect(&:model)
        add_items     = add_items - skip_items

        # DISCUSS: collection#[]= will call save
        #  what does #+= and #-= do?
        #  how do we prevent adding already existing items twice?

        model.songs += add_items
        model.songs -= remove_items.collect { |i| model.songs.find { |s| s.id.to_s == i.id.to_s } }
      end
    end
  end
end

class AlbumDecorator < Representable::Decorator
  include Representable::Hash

  collection :songs,

    semantics: [:skip_existing],

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



class ApiSemantics < MiniTest::Spec
  it do
    album = Model::Album.new(1, "And So I Watch You From Afar", [Model::Song.new(2, "Solidarity"), Model::Song.new(0, "Tale That Wasn't Right")])

    decorator = AlbumDecorator.new(album)
    decorator.from_hash({"songs" => [
      {"id" => 2, "title" => "Solidarity, but wrong title"}, # skip
      {"id" => 0, "title" => "Tale That Wasn't Right, but wrong title", "_action" => "remove"}, # delete
      {"id" => 4, "title" => "Capture Castles"} # add, default.
    ]})
    # missing: allow updating specific/all items in collection.

    puts decorator.represented.songs.inspect


    decorator.represented.songs.inspect.must_equal %{[#<struct Model::Song id=2, title="Solidarity">, #<struct Model::Song id=nil, title="Capture Castles">]}
  end
end

class ApiSemanticsWithUpdate < MiniTest::Spec
  class AlbumDecorator < Representable::Decorator
    include Representable::Hash

    collection :songs,

      semantics: [:update_existing],

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

  it do
    album = Model::Album.new(1, "And So I Watch You From Afar", [Model::Song.new(2, "Solidarity"), Model::Song.new(0, "Tale That Wasn't Right")])

    decorator = AlbumDecorator.new(album)
    decorator.from_hash({"songs" => [
      {"id" => 2, "title" => "Solidarity, updated!"}, # update
      {"id" => 0, "title" => "Tale That Wasn't Right, but wrong title", "_action" => "remove"}, # delete
      {"id" => 4, "title" => "Capture Castles"}, # add, default. # FIXME: this tests adding with id, keep this.
      {"title" => "Rise And Fall"}
    ]})
    # missing: allow updating specific/all items in collection.

    puts decorator.represented.songs.inspect


    decorator.represented.songs.inspect.must_equal %{[#<struct Model::Song id=2, title="Solidarity, updated!">, #<struct Model::Song id=nil, title="Capture Castles">]}
  end
end
# [
#   {"_action": "add"},
#   {"id": 2, "_action": "remove"}
# ]