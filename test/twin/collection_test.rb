require 'test_helper'

# reason: unique API for collection (adding, removing, deleting, etc.)
#         delay DB write until saving Twin

# TODO: eg "after delete hook (dynamic_delete)", after_add

class TwinCollectionTest < MiniTest::Spec
  module Model
    Song  = Struct.new(:id, :title, :album)
    Album = Struct.new(:id, :name, :songs, :artist)
  end


  module Twin
    class Song < Disposable::Twin
      property :id # DISCUSS: needed for #save.
      property :title
      property :album, :twin => Album
    end

    class Album < Disposable::Twin
      property :id # DISCUSS: needed for #save.
      property :name
      collection :songs, :twin => lambda { |*| Song }
    end
  end

  let (:song) { Model::Song.new(1, "Broken", nil) }
  let (:album) { Model::Album.new(1, "The Rest Is Silence", [song]) }

  describe "reader for collection" do
    it do
      twin = Twin::Album.new(album)

      twin.songs.size.must_equal 1
      twin.songs[0].title.must_equal "Broken"
      twin.songs.must_be_instance_of Disposable::Twin::Collection

    end
  end
end

require "disposable/twin/sync"
require "disposable/twin/save"

class TwinCollectionActiveRecordTest < MiniTest::Spec
  module Twin
    class Song < Disposable::Twin
      property :id # DISCUSS: needed for #save.
      property :title

      # property :persisted?, readonly: true # TODO: implement that!!!! for #sync

      include Sync
      include Save
    end

    class Artist < Disposable::Twin
    end

    class Album < Disposable::Twin
      property :id # DISCUSS: needed for #save.
      property :name
      collection :songs, :twin => lambda { |*| Song }
      property :artist, twin: lambda { |*| Artist }

      include Sync
      include Save
      include Setup
      include Collection::Semantics
    end
  end

  let (:album) { Album.create(name: "The Rest Is Silence") }
  let (:song1) { Song.new(title: "Snorty Pacifical Rascal") } # unsaved.
  let (:song2) { Song.create(title: "At Any Cost") } # saved.
  let (:twin) { Twin::Album.new(album) }

  it do
    # TODO: test all writers.
    twin.songs << song1 # assuming that we add AR model here.
    twin.songs << song2

    twin.songs.size.must_equal 2

    twin.songs[0].must_be_instance_of Twin::Song # twin wraps << added in twin.
    twin.songs[1].must_be_instance_of Twin::Song

    # twin.songs[0].persisted?.must_equal false
    twin.songs[0].send(:model).persisted?.must_equal false
    twin.songs[1].send(:model).persisted?.must_equal true

    album.songs.size.must_equal 0 # nothing synced, yet.

    # sync: delete removed items, add new?

    # save
    twin.save

    album.persisted?.must_equal true
    album.name.must_equal "The Rest Is Silence"

    album.songs.size.must_equal 2 # synced!

    album.songs[0].persisted?.must_equal true
    album.songs[1].persisted?.must_equal true
    album.songs[0].title.must_equal "Snorty Pacifical Rascal"
    album.songs[1].title.must_equal "At Any Cost"
  end

  # test with adding to existing collection [song1] << song2

  # TODO: #delete non-existent twin.
  describe "#delete" do
    let (:album) { Album.create(name: "The Rest Is Silence", songs: [song1]) }

    it do
      twin.songs.delete(twin.songs.first)

      twin.songs.size.must_equal 0
      album.songs.size.must_equal 1 # not synced, yet.

      twin.save

      twin.songs.size.must_equal 0
      album.songs.size.must_equal 0
      song1.persisted?.must_equal true
    end

    # non-existant delete.
    it do
      twin.songs.delete("non-existant") # won't delete anything.
      twin.songs.size.must_equal 1
    end
  end

  describe "#destroy" do
    let (:album) { Album.create(name: "The Rest Is Silence", songs: [song1]) }

    it do
      twin.songs.destroy(twin.songs.first)

      twin.songs.size.must_equal 0
      album.songs.size.must_equal 1 # not synced, yet.

      twin.save

      twin.songs.size.must_equal 0
      album.songs.size.must_equal 0
      song1.persisted?.must_equal false
    end
  end


  describe "#added" do
    let (:album) { Album.create(name: "The Rest Is Silence", songs: [song1]) }

    it do
      twin = Twin::Album.new(album)

      twin.songs.added.must_equal []
      twin.songs << song2
      twin.songs.added.must_equal [twin.songs[1]]
      twin.songs.insert(2, song3 = Song.new)
      twin.songs.added.must_equal [twin.songs[1], twin.songs[2]]

      # TODO: what to do if we override an item (insert)?
    end
  end

  describe "#deleted" do
    let (:album) { Album.create(name: "The Rest Is Silence", songs: [song1, song2, song3 = Song.new]) }

    it do
      twin = Twin::Album.new(album)

      twin.songs.deleted.must_equal []

      twin.songs.delete(deleted1 = twin.songs[-1])
      twin.songs.delete(deleted2 = twin.songs[-1])

      twin.songs.must_equal [twin.songs[0]]

      twin.songs.deleted.must_equal [deleted1, deleted2]
    end

    # non-existant delete.
    it do
      twin.songs.delete("non-existant") # won't delete anything.
      twin.songs.deleted.must_equal []
    end
  end
end


class CollectionUnitTest < MiniTest::Spec
  module Twin
    class Album < Disposable::Twin
    end

    class Song < Disposable::Twin
      property :album, twin: Twin::Album
    end
  end

  module Model
    Album = Struct.new(:id, :name, :songs, :artist)
  end

  let(:collection) { Disposable::Twin::Collection.new(Disposable::Twin::Twinner.new(Twin::Song.representer_class.representable_attrs.get(:album)), []) }

  # #insert(index, model)
  it do
    collection.insert(0, Model::Album.new).must_be_instance_of Twin::Album
  end

  # #<<
  it do
    collection << Model::Album.new
    collection[0].must_be_instance_of Twin::Album
  end
end