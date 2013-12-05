require 'test_helper'

class FacadeTest < MiniTest::Spec
  class Track < ::Track
  end

  class Song < Disposable::Facade
    facades Track
  end

  class Hit < Disposable::Facade
  end

  let (:track) { Track.new }

  it { track.class.must_equal Track }
  it { track.facade.class.must_equal Song }

  it "allows passing facade name" do # FIXME: what if track doesn't have Facadable?
    track.facade(Hit).class.must_equal Hit
  end
  # DISCUSS: should this be Hit.facade(track) ?

  it "facades only once" do
  end

  describe "#id" do
    let (:track) do Track.new.instance_eval {
      def id; 1; end
      self }
    end

    # DISCUSS: this actually tests Facadable.
    it "calls original" do
      track.facade.id.must_equal 1
    end
  end

  it "responds to #facaded" do
    Song.new(facaded = Object.new).facaded.must_equal facaded
  end
end

class FacadesWithOptionsTest < MiniTest::Spec
  class Track < ::Track
  end

  class Song < Disposable::Facade
    facades Track, :if => lambda { |t| t.title }
  end

  it { Track.new(:title => "Trudging").facade.class.must_equal Song }
  it { Track.new.facade.class.must_equal Track }

  describe "#facade!" do
    it "ignores :if" do
      Track.new.facade!.class.must_equal Song
    end
  end
end