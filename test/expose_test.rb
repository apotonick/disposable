require "test_helper"
require "disposable/expose"
require "disposable/composition"

# Disposable::Expose.
class ExposeTest < MiniTest::Spec
  module Model
    Album = Struct.new(:id, :name)
  end

  module Twin
    class Album < Disposable::Twin
      property :id
      property :title, from: :name
    end
  end

  class AlbumExpose < Disposable::Expose
    from Twin::Album.representer_class
  end

  let (:album) { Model::Album.new(1, "Dick Sandwich") }
  subject { AlbumExpose.new(album) }

  describe "readers" do
    it  do
      subject.id.must_equal 1
      subject.title.must_equal "Dick Sandwich"
    end
  end


  describe "writers" do
    it do
      subject.id = 3
      subject.title = "Eclipse"

      subject.id.must_equal 3
      subject.title.must_equal "Eclipse"
      album.id.must_equal 3
      album.name.must_equal "Eclipse"
    end
  end
end


# Disposable::Composition.
class ExposeCompositionTest < MiniTest::Spec
  module Model
    Band  = Struct.new(:id)
    Album = Struct.new(:id, :name)
  end

  module Twin
    class Album < Disposable::Twin
      property :id,                 on: :album
      property :name,               on: :album
      property :band_id, from: :id, on: :band
    end

    class AlbumComposition < Disposable::Composition
      from Twin::Album.representer_class
    end
  end

  let (:band) { Model::Band.new(1) }
  let (:album) { Model::Album.new(2, "Dick Sandwich") }
  subject { Twin::AlbumComposition.new(album: album, band: band) }


  describe "readers" do
    it { subject.id.must_equal 2 }
    it { subject.band_id.must_equal 1 }
    it { subject.name.must_equal "Dick Sandwich" }
  end


  describe "writers" do
    it do
      subject.id = 3
      subject.band_id = 4
      subject.name = "Eclipse"

      subject.id.must_equal 3
      subject.band_id.must_equal 4
      subject.name.must_equal "Eclipse"
      band.id.must_equal 4
      album.id.must_equal 3
      album.name.must_equal "Eclipse"
    end
  end
end