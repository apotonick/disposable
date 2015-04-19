require "test_helper"
require "disposable/twin"
require "ostruct"

module Model
  Song  = Struct.new(:id, :title)
  Album = Struct.new(:id, :name, :songs)
end

module Representable
  class Semantics
    class Semantic
    end

    class SkipExisting < Semantic
      def self.call(model, fragment, index, options)
        return unless model.songs.collect { |s| s.id.to_s }.include?(fragment["id"].to_s) #and fragment["_action"] != "remove"

        puts "¬¬¬¬¬¬¬ skipping #{fragment}"
        return Skip.new(fragment)
      end
    end

    class Add < Semantic # old representable behavior.
      def self.call(model, fragment, index, options)
        binding = options.binding.clone
        binding.instance_variable_get(:@definition).delete!(:instance) # FIXME: sucks!
        Representable::Deserializer.new(binding).(fragment, options.user_options) # is that for :update?

        #Model::Song.new # TODO: Original behaviour with :class, :extend, and so on.
      end
    end

    class UpdateExisting < Semantic
      def self.call(model, fragment, index, options)
        puts "yooo #{model.songs.inspect}"
        return unless res= model.songs.find { |s| s.id.to_s == fragment["id"].to_s }

          # update existing, but somehow mark it so it does not get added, again.

          return Update.new(res)
      end
    end


    class Skip < OpenStruct
    end
    class Remove < Skip
      def self.call(model, fragment, index, options)
        return unless fragment["_action"] == "remove" # TODO: check if feature enabled.

        Remove.new(fragment)
      end

    end

    require 'delegate'
    class Update < SimpleDelegator
    end

    # Per parsed collection item, mark the to-be-populated model for removal, skipping or adding.
    # This code is called right before #from_format is called on the model.
    # Semantical behavior is inferred from the fragment making this code document- and format-specific.

    # remove: unlink from association
    # skip_existing
    # update_existing
    # [add]

    # default behavior: - add_new

    class Instance
      include Uber::Callable

      def call(model, fragment, index, options)
        semantics = options.binding[:semantics]

        semantics.each do |semantic|
          res = semantic.(model, fragment, index, options) and return res
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
        skip_items  += values.find_all { |i| i.instance_of?(Representable::Semantics::Update) } # TODO: merge with above!

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

# TODO: test remove when :remove semantic is not set.

class AlbumDecorator < Representable::Decorator
  include Representable::Hash

  collection :songs,

    # semantics: [:skip_existing, :add, :remove],
    semantics: [Representable::Semantics::Remove, Representable::Semantics::SkipExisting, Representable::Semantics::Add],

    instance: Representable::Semantics::Instance.new,

      pass_options: true,
    # skip_parse: lambda { |fragment, *args|
    #   puts "sss #{fragment.inspect}... #{songs.collect { |s| s.id.to_s }.inspect}"
    #   songs.collect { |s| s.id.to_s }.include?(fragment["id"].to_s) }, # read-only existing.

    setter: Representable::Semantics::Setter.new,


    class: Model::Song do # add new to existing collection.

      # only add new songs
      property :title
  end
end



class ApiSemantics < MiniTest::Spec
  it "xxx" do
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

      semantics: [Representable::Semantics::Remove, Representable::Semantics::UpdateExisting, Representable::Semantics::Add],

      instance: Representable::Semantics::Instance.new,

        pass_options: true,
        class: Model::Song,
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


    decorator.represented.songs.inspect.must_equal %{[#<struct Model::Song id=2, title="Solidarity, updated!">, #<struct Model::Song id=nil, title="Capture Castles">, #<struct Model::Song id=nil, title=\"Rise And Fall\">]}
  end
end
# [
#   {"_action": "add"},
#   {"id": 2, "_action": "remove"}
# ]