# frozen_string_literal: true

require 'test_helper'

class ReschemeTest < MiniTest::Spec
  module Representer
    include Representable

    property :id
    property :title, writeable: false, deserializer: { skip_parse: 'skip lambda' }
    property :songs, readable: false, deserializer: { skip_parse: 'another lambda', music: true, writeable: false } do
      property :name, as: 'Name', deserializer: { skip_parse: 'a crazy cool instance method' }
    end
  end

  module Hello
    def hello
      'hello'
    end
  end

  module Ciao
    def ciao
      'ciao'
    end
  end

  module Gday
    def hello
      "G'day"
    end
  end

  it do
    decorator = Disposable::Rescheme.from(Representer, superclass: Representable::Decorator,
                                                       include: [Representable::Hash, Hello, Gday, Ciao], # Hello will win over Gday.
                                                       options_from: :deserializer,
                                                       definitions_from: ->(nested) { nested.definitions })

    # include: works.
    _(decorator.new(nil).hello).must_equal 'hello'
    _(decorator.new(nil).ciao).must_equal 'ciao'

    _(decorator.representable_attrs.get(:id).inspect).must_equal '#<Representable::Definition ==>id @options={:name=>"id", :parse_filter=>[], :render_filter=>[]}>'
    _(decorator.representable_attrs.get(:title).inspect).must_equal '#<Representable::Definition ==>title @options={:writeable=>false, :deserializer=>{:skip_parse=>"skip lambda"}, :name=>"title", :parse_filter=>[], :render_filter=>[], :skip_parse=>"skip lambda"}>'

    songs = decorator.representable_attrs.get(:songs)
    options = songs.instance_variable_get(:@options)
    options[:nested].extend(Declarative::Inspect)
    _(options.inspect).must_equal '{:readable=>false, :deserializer=>{:skip_parse=>"another lambda", :music=>true, :writeable=>false}, :nested=>#<Class:>, :extend=>#<Class:>, :name=>"songs", :parse_filter=>[], :render_filter=>[], :skip_parse=>"another lambda", :music=>true, :writeable=>false}'

    # nested works.
    _(options[:nested].new(nil).hello).must_equal 'hello'
    _(options[:nested].new(nil).ciao).must_equal 'ciao'

    _(options[:nested].representable_attrs.get(:name).inspect).must_equal '#<Representable::Definition ==>name @options={:as=>"Name", :deserializer=>{:skip_parse=>"a crazy cool instance method"}, :name=>"name", :parse_filter=>[], :render_filter=>[], :skip_parse=>"a crazy cool instance method"}>'
  end

  # :options_from and :include is optional
  it do
    decorator = Disposable::Rescheme.from(Representer, superclass: Representable::Decorator, include: [Representable::Hash],
                                                       definitions_from: ->(nested) { nested.definitions })

    _(decorator.representable_attrs.get(:id).inspect).must_equal '#<Representable::Definition ==>id @options={:name=>"id", :parse_filter=>[], :render_filter=>[]}>'
    _(decorator.representable_attrs.get(:title).inspect).must_equal '#<Representable::Definition ==>title @options={:writeable=>false, :deserializer=>{:skip_parse=>"skip lambda"}, :name=>"title", :parse_filter=>[], :render_filter=>[]}>'
  end

  # :exclude_options allows skipping particular options when copying.
  it do
    decorator = Disposable::Rescheme.from(Representer, superclass: Representable::Decorator, include: [Representable::Hash],
                                                       definitions_from: ->(nested) { nested.definitions },
                                                       exclude_options: [:deserializer])

    _(decorator.representable_attrs.get(:id).inspect).must_equal '#<Representable::Definition ==>id @options={:name=>"id", :parse_filter=>[], :render_filter=>[]}>'
    _(decorator.representable_attrs.get(:title).inspect).must_equal '#<Representable::Definition ==>title @options={:writeable=>false, :name=>"title", :parse_filter=>[], :render_filter=>[]}>'
    _(decorator.representable_attrs.get(:songs).representer_module.representable_attrs.get(:name).inspect).must_equal '#<Representable::Definition ==>name @options={:as=>"Name", :name=>"name", :parse_filter=>[], :render_filter=>[]}>'
  end

  it '::from with block allows customizing every definition and returns representer' do
    decorator = Disposable::Rescheme.from(Representer, include: [Representable::Hash],
                                                       superclass: Representable::Decorator,
                                                       definitions_from: ->(nested) { nested.definitions }) { |dfn| dfn.merge!(amazing: true) }

    _(decorator.representable_attrs.get(:id).inspect).must_equal '#<Representable::Definition ==>id @options={:name=>"id", :parse_filter=>[], :render_filter=>[], :amazing=>true}>'
    _(decorator.representable_attrs.get(:songs).representer_module.representable_attrs.get(:name).inspect).must_equal '#<Representable::Definition ==>name @options={:as=>"Name", :deserializer=>{:skip_parse=>"a crazy cool instance method"}, :name=>"name", :parse_filter=>[], :render_filter=>[], :amazing=>true}>'
  end

  it 'recursive: false only copies first level' do
    decorator = Disposable::Rescheme.from(Representer, include: [Representable::Hash],
                                                       superclass: Representable::Decorator,
                                                       definitions_from: ->(nested) { nested.definitions },
                                                       recursive: false,
                                                       exclude_options: [:deserializer])

    _(decorator.representable_attrs.get(:title).inspect).must_equal '#<Representable::Definition ==>title @options={:writeable=>false, :name=>"title", :parse_filter=>[], :render_filter=>[]}>'
    _(decorator.representable_attrs.get(:songs).representer_module.representable_attrs.get(:name).inspect).must_equal '#<Representable::Definition ==>name @options={:as=>"Name", :deserializer=>{:skip_parse=>"a crazy cool instance method"}, :name=>"name", :parse_filter=>[], :render_filter=>[]}>'
  end

  describe ':exclude_properties' do
    module SmallRepresenter
      include Representable

      property :id
      property :songs do
        property :id
        property :name, as: 'Name'
      end
    end

    it do
      decorator = Disposable::Rescheme.from(SmallRepresenter,
                                            include: [Representable::Hash],
                                            superclass: Representable::Decorator,
                                            definitions_from: ->(nested) { nested.definitions },
                                            recursive: true,
                                            exclude_properties: [:id])

      _(decorator.definitions.keys).must_equal ['songs']
      _(decorator.definitions.get(:songs).representer_module.definitions.keys).must_equal ['name']
    end
  end
end

class TwinReschemeTest < MiniTest::Spec
  class Artist < Disposable::Twin
    property :name
  end

  class Album < Disposable::Twin
    property :artist, twin: Artist
  end

  it do
    decorator = Disposable::Rescheme.from(Album, superclass: Representable::Decorator, include: [Representable::Hash],
                                                 definitions_from: ->(nested) { nested.definitions })

    artist = decorator.representable_attrs.get(:artist)
    options = artist.instance_variable_get(:@options)
    nested_extend = options[:nested]
    _(options.extend(Declarative::Inspect).inspect).must_equal '{:private_name=>:artist, :nested=>#<Class:>, :name=>"artist", :extend=>#<Class:>, :parse_filter=>[], :render_filter=>[]}'
    assert nested_extend < Representable::Decorator
    _(nested_extend.representable_attrs.get(:name).inspect).must_equal '#<Representable::Definition ==>name @options={:private_name=>:name, :name=>"name", :parse_filter=>[], :render_filter=>[]}>'
  end
end
