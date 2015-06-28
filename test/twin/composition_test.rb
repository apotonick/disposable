require 'test_helper'

# Disposable::Twin::Composition.
class TwinCompositionTest < MiniTest::Spec
  class Request < Disposable::Twin
    include Sync
    include Save
    include Composition

    property :song_title, on: :song, from: :title
    property :song_id,    on: :song, from: :id

    property :name,       on: :requester
    property :id,         on: :requester
    property :captcha,    readable: false, writeable: false, on: :requester # TODO: allow both, virtual with and without :on.
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


    res = request.save
    res.must_equal true

    # make sure models got synced and saved.
    song.id.must_equal 2
    song.title.must_equal "Tease"
    requester.id.must_equal 1
    requester.name.must_equal "Wooten"

    song.saved?.must_equal true
    requester.saved?.must_equal true
  end

  # save with block.
  it do
    request.song_title = "Tease"
    request.name = "Wooten"
    request.captcha = "Awesome!"

    # does not write to model.
    song.title.must_equal "Extraction"
    requester.name.must_equal "Greg Howe"


    nested_hash = nil
    request.save do |hash|
      nested_hash = hash
    end

    nested_hash.must_equal(:song=>{"title"=>"Tease", "id"=>2}, :requester=>{"name"=>"Wooten", "id"=>1, "captcha"=>"Awesome!"})
  end

  # save with one unsaveable model.
    #save returns result.
  it do
    song.instance_eval { def save; false; end }
    request.save.must_equal false
  end
end