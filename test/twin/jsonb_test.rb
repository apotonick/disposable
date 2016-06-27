require "test_helper"
require "disposable/twin/jsonb"

class JSONBTest < MiniTest::Spec
  Model = Struct.new(:id, :content)

  class Song < Disposable::Twin
    feature Sync
    include JSONB

    property :id
    property :content, jsonb: true do
      property :title
      property :band do
        property :name

        property :label do
          property :location
        end
      end
    end
  end

  # puts Song.definitions.get(:content)[:nested].definitions.get(:band).inspect

  it "allows reading from existing hash" do
    model = Model.new(1, {})
    model.inspect.must_equal "#<struct JSONBTest::Model id=1, content={}>"

    song = Song.new(model)
    song.id.must_equal 1
    song.content.title.must_equal nil
    song.content.band.name.must_equal nil
    song.content.band.label.location.must_equal nil

    # model's hash hasn't changed.
    model.inspect.must_equal "#<struct JSONBTest::Model id=1, content={}>"
  end

  it "defaults to hash when value is nil" do
    model = Model.new(1)
    model.inspect.must_equal "#<struct JSONBTest::Model id=1, content=nil>"

    song = Song.new(model)
    song.id.must_equal 1
    song.content.title.must_equal nil
    song.content.band.name.must_equal nil
    song.content.band.label.location.must_equal nil

    # model's hash hasn't changed.
    model.inspect.must_equal "#<struct JSONBTest::Model id=1, content=nil>"
  end

  it "#sync writes to model" do
    model = Model.new

    song = Song.new(model)
    song.content.band.label.location = "San Francisco"

    song.sync

    model.inspect.must_equal "#<struct JSONBTest::Model id=nil, content={\"band\"=>{\"label\"=>{\"location\"=>\"San Francisco\"}}}>"
  end

  it "doesn't erase existing, undeclared content" do
    model = Model.new(nil, {"artist"=>{}})

    song = Song.new(model)
    song.content.band.label.location = "San Francisco"

    # puts song.content.class.ancestors
    song.sync

    model.inspect.must_equal "#<struct JSONBTest::Model id=nil, content={\"artist\"=>{}, \"band\"=>{\"label\"=>{\"location\"=>\"San Francisco\"}}}>"
  end

  it "doesn't erase existing, undeclared content in existing content" do
    model = Model.new(nil, {"band"=>{ "label" => { "owner" => "Brett Gurewitz" }, "genre" => "Punkrock" }})

    song = Song.new(model)
    song.content.band.label.location = "San Francisco"

    song.sync

    model.inspect.must_equal "#<struct JSONBTest::Model id=nil, content={\"band\"=>{\"label\"=>{\"owner\"=>\"Brett Gurewitz\", \"location\"=>\"San Francisco\"}, \"genre\"=>\"Punkrock\"}}>"
  end


  describe "features propagation" do
    module UUID
      def uuid
        "1224"
      end
    end

    class Hit < Disposable::Twin
      include JSONB
      feature UUID

      property :id
      property :content, jsonb: true do
        property :title
        property :band do
          property :name
        end
      end
    end

    it "includes features into all nested twins" do
      song = Hit.new(Model.new)
      song.uuid.must_equal "1224"
      song.content.uuid.must_equal "1224"
      song.content.band.uuid.must_equal "1224"
    end
  end

  describe "coercion" do
    require "disposable/twin/coercion"
    class Coercing < Disposable::Twin
      include JSONB
      feature Coercion

      property :id, type: Types::Coercible::Int
      property :content, jsonb: true do
        property :title
        property :band do
          property :name, type: Types::Coercible::String
        end
      end
    end

    it "coerces" do
      song = Coercing.new(Model.new(1))
      song.id = "9"
      song.id.must_equal 9
      song.content.band.name = 18
      song.content.band.name.must_equal "18"
    end
  end
end

# fixme: make sure default hash is different for every invocation, and not created at compile time.
