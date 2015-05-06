require "test_helper"

class FormTest < MiniTest::Spec
  module Model
    Song  = Struct.new(:id, :composer)
    Album = Struct.new(:id, :name, :songs, :artist)
    Artist = Struct.new(:id)
  end

  class AlbumForm < Disposable::Twin
    include Setup
    object_representer_class.send :register_feature, Setup # include in every inline representer (comes from representable).

    property :id
    property :name

    collection :songs do # default_inline_class: Disposable::Twin
      # include Setup

      property :id

      property :composer do
        # include Setup

        property :id
      end
    end

    property :artist do
      # include Setup

      property :id
    end
  end

  let (:song) { Model::Song.new(1) }
  let (:song_with_composer) { Model::Song.new(3, composer) }
  let (:composer) { Model::Artist.new(2) }
  let (:artist) { Model::Artist.new(9) }
  let (:album) { Model::Album.new(0, "Toto Live", [song, song_with_composer], artist) }

  it do
    twin = AlbumForm.new(album)

    # 1. create representer
    # 2. deserialize on twin
    # 3. validate twin

    twin.validate({
      name: "Live In A Dive",
      songs: [
        {id: 1}, # old
        {id: 3}, # no composer this time?
        {id: "Talk Show"}, # new one.
        {id: "Kinetic", composer: {id: "Osker"}}
      ]
    }).must_equal false
  end
end