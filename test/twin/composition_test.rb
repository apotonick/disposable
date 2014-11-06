require 'test_helper'

require 'disposable/twin/composition'

class TwinCompositionTest < MiniTest::Spec
  class Request < Disposable::Twin::Composition
    property :song_title, :on => :song, :from => :title
    property :song_id,    :on => :song, :from => :id

    property :name,       :on => :requester
    property :id,         :on => :requester

    # map ...

    # def id
    # make map(name, options)
    # option :played?
  end

  module Model
    Song      = Struct.new(:id, :title, :album)
    Requester = Struct.new(:id, :name)
  end

  let (:requester) { Model::Requester.new(1, "Greg Howe") }
  let (:song) { Model::Song.new(2, "Extraction") }

  let (:request) { Request.new(:song => song, :requester => requester) }

  it { request.song_title.must_equal "Extraction" }
  it { request.name.must_equal "Greg Howe" }


  describe "setter" do
    before do
      request.song_title = "Tease"
      request.name = "Wooten"
    end

    it { request.song_title.must_equal "Tease" }
    # no writing to model.
    it { song.title.must_equal "Extraction" }
    it { request.name.must_equal "Wooten" }
  end
end