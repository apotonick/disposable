require "test_helper"

require "disposable/twin/schema"

class SchemaTest < MiniTest::Spec
  module Representer
    include Representable

    property :id
    property :title, writeable: false, deserializer: {skip_parse: "skip lambda"}
    property :songs, readable: false, deserializer: {skip_parse: "another lambda", music: true} do
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
    options.inspect.must_equal "{:readable=>false, :deserializer=>{:skip_parse=>\"another lambda\", :music=>true}, :parse_filter=>[], :render_filter=>[], :as=>\"songs\", :_inline=>true, :skip_parse=>\"another lambda\", :music=>true}"

    # nested works.
    nested_extend.new(nil).hello.must_equal "hello"
    nested_extend.new(nil).ciao.must_equal "ciao"

    nested_extend.representable_attrs.get(:name).inspect.must_equal "#<Representable::Definition ==>name @options={:as=>\"Name\", :deserializer=>{:skip_parse=>\"a crazy cool instance method\"}, :parse_filter=>[], :render_filter=>[], :skip_parse=>\"a crazy cool instance method\"}>"
  end
end