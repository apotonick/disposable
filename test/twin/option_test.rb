require "test_helper"

class TwinOptionTest < MiniTest::Spec
  module Model
    Song  = Struct.new(:id, :title, :album)
    Album = Struct.new(:id, :name, :songs, :artist)
    Artist = Struct.new(:id)
  end


  class Song < Disposable::Twin
    include Sync

    property :id # DISCUSS: needed for #save.
    property :title

    option :preview?
    option :highlight?
  end

  let (:song) { Model::Song.new(1, "Broken") }
  let (:twin) { Song.new(song, :preview? => false) }


  it do
    # properties are read from model.
    twin.id.must_equal 1
    twin.title.must_equal "Broken"

    # option is not delegated to model.
    twin.preview?.must_equal false
    # not passing option means zero.
    twin.highlight?.must_equal nil

    # passing both options.
    Song.new(song, preview?: true, highlight?: false).preview?.must_equal true

    # doesn't sync option
    twin.sync
  end


  # Option works with Setup.
  class SetupSong < Disposable::Twin
    include Setup

    property :id

    option :preview?
  end

  it do
    twin = SetupSong.new(song, :preview? => false)

    twin.id.must_equal 1
    twin.preview?.must_equal false
  end
end

