require "test_helper"

class InheritTest < MiniTest::Spec
  module Model
    Song  = Struct.new(:title, :album)
    Album = Struct.new(:name, :songs, :artist, :with_custom_getter, :with_custom_setter)
    Artist = Struct.new(:name)
  end

  module Twin
    class Album < Disposable::Twin
      feature Setup

      property :name, fromage: :_name

      collection :songs do
        property :name
      end

      property :artist do
        property :name

        def artist_id
          1
        end
      end

      property :with_custom_getter
      property :with_custom_setter

      def with_custom_getter
        "my custom getter"
      end

      def with_custom_setter=(val)
        super("my custom setter")
      end
    end

    class EmptyCompilation < Album
    end

    class Compilation < Album
      property :name, writeable: false, inherit: true

      property :artist, inherit: true do

      end
    end
  end

  # definitions are not shared.
  it do
    Twin::Album.definitions.get(:name).extend(Declarative::Inspect).inspect.must_equal "#<Disposable::Twin::Definition: @options={:fromage=>:_name, :private_name=>:name, :name=>\"name\"}>"
    Twin::Compilation.definitions.get(:name).extend(Declarative::Inspect).inspect.must_equal "#<Disposable::Twin::Definition: @options={:fromage=>:_name, :private_name=>:name, :name=>\"name\", :writeable=>false}>" # FIXME: where did :inherit go?
  end


  let (:album) { Model::Album.new("In The Meantime And Inbetween Time", [], Model::Artist.new) }

  it { Twin::Album.new(album).artist.artist_id.must_equal 1 }

  # inherit inline twins when not overriding.
  it { Twin::EmptyCompilation.new(album).artist.artist_id.must_equal 1 }

  # inherit inline twins when overriding.
  it { Twin::Compilation.new(album).artist.artist_id.must_equal 1 }

  describe "custom getters get inherited" do
    let (:album) { Model::Album.new("", [], Model::Artist.new, "this gets ignored", "") }

    it do
      compilation = Twin::Compilation.new(album)
      compilation.with_custom_getter.must_equal("my custom getter")
    end
  end

  describe "custom setters get inherited" do
    let (:album) { Model::Album.new("", [], Model::Artist.new, "", "custom setter default") }

    it do
      compilation = Twin::Compilation.new(album)
      compilation.with_custom_setter = "custom setter default"
      compilation.with_custom_setter = "this gets ignored"
      compilation.with_custom_setter.must_equal("my custom setter")
    end
  end
end
