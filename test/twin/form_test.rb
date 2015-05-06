require "test_helper"

class FormTest < MiniTest::Spec
  module Model
    Song  = Struct.new(:id, :composer)
    Album = Struct.new(:id, :name, :songs, :artist)
    Artist = Struct.new(:id)
  end



  # TODO: this needs tests and should probably go to Representable. we can move tests from Reform for that.
  class Converter
    def self.from(source_class, options) # TODO: can we re-use this for all the decorator logic in #validate, etc?
      representer = Class.new(options[:superclass])
      representer.send :include, *options[:include]

      source_class.representable_attrs.each do |dfn|
        representer.property(dfn.name, dfn.instance_variable_get(:@options)) unless dfn[:extend]

        if twin = dfn[:twin]
          twin = twin.evaluate(nil)

          dfn_options = dfn.instance_variable_get(:@options).merge(extend: from(twin.object_representer_class, options))

          if dfn_options[:deserializer]
            dfn_options.merge!(dfn_options[:deserializer])
          end

          representer.property(dfn.name, dfn_options)
        end
      end

      representer
    end
  end

  module Validate # TODO: use from reform.
    def validate(params)
      # 1. create representer
      # 2. deserialize on twin
      # 3. validate twin

      # pp params

      deserializer = Converter.from(self.class.object_representer_class,
        :include    => [Representable::Hash::AllowSymbols, Representable::Hash],
        :superclass => Representable::Decorator)

      # pp deserializer.representable_attrs.get(:songs).representer_module.representable_attrs.

      deserializer.new(self).
        # extend(Representable::Debug).
        from_hash(params)

      pp self
    end
  end

  class AlbumForm < Disposable::Twin
    include Setup
    # object_representer_class.send :register_feature, Setup # include in every inline representer (comes from representable).

    property :id
    property :name

    collection :songs,
      # populate_if_empty: {},
      pass_options: true,
      deserializer: {instance: lambda { |fragment, index, options|
              collection = options.binding.get
              (item = collection[index]) ? item : collection.insert(index, Model::Song.new) },
      setter: nil} do # default_inline_class: Disposable::Twin
      include Setup
      property :id

      property :composer,
        deserializer: { instance: lambda { |fragment, options| (item = options.binding.get) ? item : Model::Artist.new } } do
        include Setup
        property :id
      end
    end

    property :artist do
      include Setup
      property :id
    end

    include Validate # TODO: use from reform.
  end

  let (:song) { Model::Song.new(1) }
  let (:song_with_composer) { Model::Song.new(3, composer) }
  let (:composer) { Model::Artist.new(2) }
  let (:artist) { Model::Artist.new(9) }
  let (:album) { Model::Album.new(0, "Toto Live", [song, song_with_composer], artist) }

  it do
    twin = AlbumForm.new(album)

    twin.songs.must_be_instance_of Disposable::Twin::Collection

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
    # }).must_equal false
    })

    # again, test the deserialization.
    twin.songs[2].must_be_kind_of Disposable::Twin
    twin.songs[2].id.must_equal "Talk Show"
    twin.songs[3].id.must_equal "Kinetic"
    twin.songs[3].composer.must_be_kind_of Disposable::Twin
    twin.songs[3].composer.id.must_equal "Osker"
  end
end