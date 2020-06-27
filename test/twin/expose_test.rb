# frozen_string_literal: true

require 'test_helper'

# Disposable::Twin::Expose.
class TwinExposeTest < MiniTest::Spec
  class Request < Disposable::Twin
    feature Sync
    feature Save
    feature Expose

    property :song_title, from: :title
    property :id
    # virtual.
    property :captcha, readable: false, writeable: false
    # nested.
    property :album do
      property :name, from: :getName
    end
  end

  module Model
    Song  = Struct.new(:id, :title, :album)
    Album = Struct.new(:getName)
  end

  let(:album) { Model::Album.new('Appeal To Reason').extend(Disposable::Saveable) }
  let(:song) { Model::Song.new(2, 'Extraction', album).extend(Disposable::Saveable) }

  let(:request) { Request.new(song) }

  it do
    _(request.song_title).must_equal 'Extraction'
    _(request.id).must_equal 2

    request.song_title = 'Tease'
    request.id = 1

    _(request.song_title).must_equal 'Tease'
    _(request.id).must_equal 1

    # does not write to model.
    _(song.title).must_equal 'Extraction'
    _(song.id).must_equal 2

    request.save

    # make sure models got synced and saved.
    _(song.id).must_equal 1
    _(song.title).must_equal 'Tease'
    _(song.album).must_equal album # nested objects don't get twinned or anything.

    _(song.saved?).must_equal true
  end

  # save with block.
  it do
    request.song_title = 'Tease'
    request.id = 1
    request.captcha = 'Awesome!'

    nested_hash = nil
    request.save do |hash|
      nested_hash = hash
    end

    _(nested_hash).must_equal({ 'title' => 'Tease', 'id' => 1, 'captcha' => 'Awesome!', 'album' => { 'getName' => 'Appeal To Reason' } })

    # does not write to model.
    _(song.title).must_equal 'Extraction'
    _(song.id).must_equal 2
    _(album.getName).must_equal 'Appeal To Reason'
  end
end
