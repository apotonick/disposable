require "test_helper"

require "disposable/twin/schema"

class SchemaTest < MiniTest::Spec
  module Representer
    include Representable

    property :id
    property :title, writeable: false, deserializer: {skip_parse: "skip lambda"}
    property :songs, readable: false, deserializer: {skip_parse: "another lambda", music: true, writeable: false} do
      property :name, as: "Name", deserializer: {skip_parse: "a crazy cool instance method"}
    end
  end

  module Hello
    def hello
      "hello"
    end
  end

  module Ciao
    def ciao
      "ciao"
    end
  end

  module Gday
    def hello
      "G'day"
    end
  end

  it do
    decorator = Disposable::Twin::Schema.from(Representer, superclass: Representable::Decorator,
      include: [Hello, Gday, Ciao], # Hello will win over Gday.
      options_from: :deserializer,
      representer_from: lambda { |nested| nested }
    )

    # include: works.
    decorator.new(nil).hello.must_equal "hello"
    decorator.new(nil).ciao.must_equal "ciao"

    decorator.representable_attrs.get(:id).inspect.must_equal "#<Representable::Definition ==>id @options={:parse_filter=>[], :render_filter=>[], :as=>\"id\"}>"
    decorator.representable_attrs.get(:title).inspect.must_equal "#<Representable::Definition ==>title @options={:writeable=>false, :deserializer=>{:skip_parse=>\"skip lambda\"}, :parse_filter=>[], :render_filter=>[], :as=>\"title\", :skip_parse=>\"skip lambda\"}>"

    songs = decorator.representable_attrs.get(:songs)
    options = songs.instance_variable_get(:@options)
    nested_extend = options.delete(:extend)
    options.inspect.must_equal "{:readable=>false, :deserializer=>{:skip_parse=>\"another lambda\", :music=>true, :writeable=>false}, :parse_filter=>[], :render_filter=>[], :as=>\"songs\", :_inline=>true, :skip_parse=>\"another lambda\", :music=>true, :writeable=>false}"

    # nested works.
    nested_extend.new(nil).hello.must_equal "hello"
    nested_extend.new(nil).ciao.must_equal "ciao"

    nested_extend.representable_attrs.get(:name).inspect.must_equal "#<Representable::Definition ==>name @options={:as=>\"Name\", :deserializer=>{:skip_parse=>\"a crazy cool instance method\"}, :parse_filter=>[], :render_filter=>[], :skip_parse=>\"a crazy cool instance method\"}>"
  end

  # :options_from and :include is optional
  it do
    decorator = Disposable::Twin::Schema.from(Representer, superclass: Representable::Decorator,
      representer_from: lambda { |nested| nested }
    )

    decorator.representable_attrs.get(:id).inspect.must_equal "#<Representable::Definition ==>id @options={:parse_filter=>[], :render_filter=>[], :as=>\"id\"}>"
    decorator.representable_attrs.get(:title).inspect.must_equal "#<Representable::Definition ==>title @options={:writeable=>false, :deserializer=>{:skip_parse=>\"skip lambda\"}, :parse_filter=>[], :render_filter=>[], :as=>\"title\"}>"
  end


  # :exclude_options allows skipping particular options when copying.
  it do
    decorator = Disposable::Twin::Schema.from(Representer, superclass: Representable::Decorator,
      representer_from: lambda { |nested| nested },
      exclude_options: [:deserializer]
    )

    decorator.representable_attrs.get(:id).inspect.must_equal "#<Representable::Definition ==>id @options={:parse_filter=>[], :render_filter=>[], :as=>\"id\"}>"
    decorator.representable_attrs.get(:title).inspect.must_equal "#<Representable::Definition ==>title @options={:writeable=>false, :parse_filter=>[], :render_filter=>[], :as=>\"title\"}>"
    decorator.representable_attrs.get(:songs).representer_module.representable_attrs.get(:name).inspect.must_equal "#<Representable::Definition ==>name @options={:as=>\"Name\", :parse_filter=>[], :render_filter=>[]}>"
  end


  it "::from with block allows customizing every definition and returns representer" do
    decorator = Disposable::Twin::Schema.from(Representer,
      superclass:       Representable::Decorator,
      representer_from: lambda { |nested| nested },
    ) { |dfn| dfn.merge!(amazing: true) }

    decorator.representable_attrs.get(:id).inspect.must_equal "#<Representable::Definition ==>id @options={:parse_filter=>[], :render_filter=>[], :as=>\"id\", :amazing=>true}>"
    decorator.representable_attrs.get(:songs).representer_module.representable_attrs.get(:name).inspect.must_equal "#<Representable::Definition ==>name @options={:as=>\"Name\", :deserializer=>{:skip_parse=>\"a crazy cool instance method\"}, :parse_filter=>[], :render_filter=>[], :amazing=>true}>"
  end

  it "recursive: false only copies first level" do
    decorator = Disposable::Twin::Schema.from(Representer,
      superclass:       Representable::Decorator,
      representer_from: lambda { |nested| nested },
      recursive: false,
      exclude_options: [:deserializer]
    )

    decorator.representable_attrs.get(:title).inspect.must_equal "#<Representable::Definition ==>title @options={:writeable=>false, :parse_filter=>[], :render_filter=>[], :as=>\"title\"}>"
    decorator.representable_attrs.get(:songs).representer_module.representable_attrs.get(:name).inspect.must_equal "#<Representable::Definition ==>name @options={:as=>\"Name\", :deserializer=>{:skip_parse=>\"a crazy cool instance method\"}, :parse_filter=>[], :render_filter=>[]}>"
  end
end


class TwinSchemaTest < MiniTest::Spec
  class Artist < Disposable::Twin
    property :name
  end

  class Album < Disposable::Twin
    property :artist, twin: Artist
  end

  it do
    decorator = Disposable::Twin::Schema.from(Album, superclass: Representable::Decorator,
      representer_from: lambda { |nested| nested.representer_class }
    )

    artist = decorator.representable_attrs.get(:artist)
    options = artist.instance_variable_get(:@options)
    nested_extend = options.delete(:extend)
    options.inspect.must_equal "{:twin=>TwinSchemaTest::Artist, :private_name=>:artist, :parse_filter=>[], :render_filter=>[], :as=>\"artist\"}"
    assert nested_extend < Representable::Decorator
    nested_extend.representable_attrs.get(:name).inspect.must_equal "#<Representable::Definition ==>name @options={:private_name=>:name, :parse_filter=>[], :render_filter=>[], :as=>\"name\"}>"
  end
end