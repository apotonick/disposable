require 'test_helper'

class AccessorTest < MiniTest::Spec
  Song = Struct.new(:title)

  class SongForm < Disposable::Twin
    def title
      @title
    end

    def title=(value)
      @title = value.reverse if value
    end

    property :title, accessor: false
  end

  let (:song) { Song.new }

  let (:twin) { SongForm.new(song) }

  it {
    twin.title = "Remedy"
    twin.title.must_equal "ydemeR"
  }
end
