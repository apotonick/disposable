require 'test_helper'

class TwinCompositionTest < MiniTest::Spec
  class Request < Disposable::Twin
    include Sync
    include Save
    include Composition

    property :song_title, :on => :song, :from => :title
    property :song_id,    :on => :song, :from => :id

    property :name,       :on => :requester
    property :id,         :on => :requester
  end

  module Model
    Song      = Struct.new(:id, :title, :album)
    Requester = Struct.new(:id, :name)
  end

  let (:requester) { Model::Requester.new(1, "Greg Howe").extend(Disposable::Saveable) }
  let (:song) { Model::Song.new(2, "Extraction").extend(Disposable::Saveable) }

  let (:request) { Request.new(song: song, requester: requester) }

  it do
    request.song_title.must_equal "Extraction"
    request.song_id.must_equal 2
    request.name.must_equal "Greg Howe"
    request.id.must_equal 1

    request.song_title = "Tease"
    request.name = "Wooten"


    request.song_title.must_equal "Tease"
    request.name.must_equal "Wooten"

    # does not write to model.
    song.title.must_equal "Extraction"
    requester.name.must_equal "Greg Howe"


    request.save

    # make sure models got synced and saved.
    song.id.must_equal 2
    song.title.must_equal "Tease"
    requester.id.must_equal 1
    requester.name.must_equal "Wooten"

    song.saved?.must_equal true
    requester.saved?.must_equal true
  end
end