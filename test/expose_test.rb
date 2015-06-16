require "test_helper"

class ExposeTest < MiniTest::Spec
  module Model
    Band  = Struct.new(:id, :title)
    Album = Struct.new(:id, :name, :album)
  end

  module Twin
    class Album < Disposable::Twin
      property :id,                 on: :album
      property :name,               on: :album
      property :band_id, from: :id, on: :band
      property :title,              on: :band
    end

    class AlbumExpose < Disposable::Expose

    end
  end

  let (:band) { Model::Band.new(1, "Frenzal Rhomb") }
  let (:album) { Model::Album.new(2, "Dick Sandwich", "For the Term of Their Unnatural Lives") }
  subject { Twin::Album.new(:album => album, :band => band) }

  # describe "readers" do
  #   it { subject.id.must_equal 2 }
  #   it { subject.band_id.must_equal 1 }
  #   it { subject.name.must_equal "Dick Sandwich" }
  #   it { subject.album.must_equal "For the Term of Their Unnatural Lives" }
  #   it { subject.title.must_equal "Frenzal Rhomb" }
  # end


  # describe "writers" do
  #   before do
  #     subject.id = 3
  #     subject.band_id = 4
  #     subject.name = "Eclipse"
  #     subject.title = "Yngwie J. Malmsteen"
  #     subject.album = "Best Of"
  #   end

  #   it { subject.id.must_equal 3 }
  #   it { album.id.must_equal   3 }
  #   it { subject.band_id.must_equal 4 }
  #   it { band.id.must_equal 4 }
  #   it { subject.name.must_equal "Eclipse" }
  #   it { subject.title.must_equal "Yngwie J. Malmsteen" }
  #   it { album.name.must_equal "Eclipse" }
  #   it { band.title.must_equal "Yngwie J. Malmsteen" }
  #   it { subject.album.must_equal "Best Of" }
  #   it { album.album.must_equal "Best Of" }
  # end
  # # it { subject.save }

  # it "raises when non-mapped property" do
  #   assert_raises NoMethodError do
  #     subject.raise_an_exception
  #   end
  # end
end