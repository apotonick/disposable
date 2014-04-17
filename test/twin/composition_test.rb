require 'test_helper'

class CompositionTest < MiniTest::Spec
  module Model
    Band  = Struct.new(:id, :title,)
    Album = Struct.new(:id, :name)
  end

  module Twin
    class Album #< Disposable::Twin
      include Disposable::Composition
      extend Disposable::Composition::ClassMethods # FIXME.

      # property :id # DISCUSS: needed for #save.
      # property :name,   :on => :album
      # property :title,  :on => :band # as: :band_name

      # model Model::Album

      map( {:album => [:id, :name], :band => [:title]} )
    end
  end

  let (:band) { Model::Band.new(1, "Frenzal Rhomb") }
  let (:album) { Model::Album.new(2, "Dick Sandwhich") }
  subject { Twin::Album.new(:album => album, :band => band) }

  # it { subject.id.must_equal 2 }
  it { subject.name.must_equal "Dick Sandwhich" }
  it { subject.title.must_equal "Frenzal Rhomb" }

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
end