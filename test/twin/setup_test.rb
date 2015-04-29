require "test_helper"

class TwinSetupTest < MiniTest::Spec
  module Model
    Song  = Struct.new(:id, :title, :album)
    Album = Struct.new(:id, :name, :songs)
  end


  module Twin
    class Album < Disposable::Twin
      property :id
      property :name
      collection :songs, :twin => lambda { |*| Song }

      extend Representer
      include Setup
    end

    class Song < Disposable::Twin
      property :id

      extend Representer
      include Setup
    end
  end


  let (:song) { Model::Song.new(1, "Broken", nil) }
  let (:album) { Model::Album.new(1, "The Rest Is Silence", [song]) }


  class Bla < Representable::Decorator
    include Representable::Object

    collection :bla
  end

  it do
    Bla.new(OpenStruct.new).from_object(OpenStruct.new bla: [OpenStruct.new])
  end

  it do
    twin = Twin::Album.new(album)

    raise twin.songs.first.inspect

    twin.songs.size.must_equal 1
    twin.songs[0].title.must_equal "Broken"
    twin.songs.must_be_instance_of Disposable::Twin::Collection
  end


end