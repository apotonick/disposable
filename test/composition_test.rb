require 'test_helper'

class CompositionTest < MiniTest::Spec
  module Model
    Band  = Struct.new(:id, :title,)
    Album = Struct.new(:id, :name)
  end

  module Twin
    class Album #< Disposable::Twin
      include Disposable::Composition

      map( {:album => [[:id], [:name]],
            :band  => [[:id, :band_id], [:title]]
          } )
    end
  end

  let (:band) { Model::Band.new(1, "Frenzal Rhomb") }
  let (:album) { Model::Album.new(2, "Dick Sandwhich") }
  subject { Twin::Album.new(:album => album, :band => band) }

  describe "readers" do
    it { subject.id.must_equal 2 }
    it { subject.band_id.must_equal 1 }
    it { subject.name.must_equal "Dick Sandwhich" }
    it { subject.title.must_equal "Frenzal Rhomb" }
  end


  describe "writers" do
    before do
      subject.id = 3
      subject.band_id = 4
      subject.name = "Eclipse"
      subject.title = "Yngwie J. Malmsteen"
    end

    it { subject.id.must_equal 3 }
    it { album.id.must_equal   3 }
    it { subject.band_id.must_equal 4 }
    it { band.id.must_equal 4 }
    it { subject.name.must_equal "Eclipse" }
    it { subject.title.must_equal "Yngwie J. Malmsteen" }
    it { album.name.must_equal "Eclipse" }
    it { band.title.must_equal "Yngwie J. Malmsteen" }
  end
  # it { subject.save }

  it "raises when non-mapped property" do
    assert_raises NoMethodError do
      subject.raise_an_exception
    end
  end


  describe "readers to models" do
    it { subject.album.object_id.must_equal album.object_id }
    it { subject.band.object_id.must_equal  band.object_id }
  end


  describe "#each" do
    it "what" do
      results = []
      subject.each { |mdl| results << mdl.object_id }
      results.must_equal([album.object_id, band.object_id])
    end
  end


  describe "#_models" do
    it { subject.send(:_models).must_equal([album, band]) }
    it { Twin::Album.new(:album => album).send(:_models).must_equal([album]) }
  end


  describe "@map" do
    let (:composition) {
      Class.new do
        include Disposable::Composition

        map( {:album => [["id"], [:name]],
              "band" => [[:id, "band_id"], [:title]]
          } )
      end
    }

    # yepp, a private test WITH interface violation, as this is still a semi-public concept.
    it { composition.instance_variable_get(:@map).must_equal({
      :id      => {:method=>:id, :model=>:album},
      :name    => {:method=>:name, :model=>:album},
      :band_id => {:method=>:id, :model=>:band},
      :title   => {:method=>:title, :model=>:band}}) }
  end
end