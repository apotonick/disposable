require 'test_helper'

# Disposable::Twin::Expose.
class TwinExposeTest < MiniTest::Spec
  class Request < Disposable::Twin
    include Sync
    include Save
    include Expose

    property :song_title, from: :title
    property :id
    property :captcha,    readable: false, writeable: false
  end

  module Model
    Song = Struct.new(:id, :title)
  end

  let (:song) { Model::Song.new(2, "Extraction").extend(Disposable::Saveable) }

  let (:request) { Request.new(song) }

  it do
    request.song_title.must_equal "Extraction"
    request.id.must_equal 2

    request.song_title = "Tease"
    request.id = 1


    request.song_title.must_equal "Tease"
    request.id.must_equal 1

    # does not write to model.
    song.title.must_equal "Extraction"
    song.id.must_equal 2


    request.save

    # make sure models got synced and saved.
    song.id.must_equal 1
    song.title.must_equal "Tease"

    song.saved?.must_equal true
  end

  # save with block.
  it do
    request.song_title = "Tease"
    request.id = 1
    request.captcha = "Awesome!"

    nested_hash = nil
    request.save do |hash|
      nested_hash = hash
    end

    nested_hash.must_equal({"title"=>"Tease", "id"=>1, "captcha" => "Awesome!"})

    # does not write to model.
    song.title.must_equal "Extraction"
    song.id.must_equal 2
  end
end