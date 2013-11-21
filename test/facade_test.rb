require 'test_helper'

class FacadeTest < MiniTest::Spec
  class Track < ::Track
  end

  class Song < Disposable::Facade
    facades Track
  end

  it { Track.new.class.must_equal Track }
  it { Track.new.facade.class.must_equal Song }

  describe "#id" do
    let (:track) do Track.new.instance_eval {
      def id; 1; end
      self }
    end

    it "calls original" do
      track.facade.id.must_equal 1
    end

  end
end

class FacadeWithOptionsTest < MiniTest::Spec
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