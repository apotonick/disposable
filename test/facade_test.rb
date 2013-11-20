require 'test_helper'

class FacadeTest < MiniTest::Spec
  class Track < ::Track
  end

  class Song < Disposable::Facade
    facades Track
  end

  it { Track.new.class.must_equal Track }
  it { Track.new.facade.class.must_equal Song }
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