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

  describe "::facade" do
    it { Hit.facade(track).class.must_equal Hit }
  end

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

class ClassFacadeTest < MiniTest::Spec
  class Track
    attr_reader :title

    def initialize(options)
      @title = options[:title] # we only save this key.
      raise "rename didn't work" if options[:name]
    end
  end

#require 'disposable/facade/active_record'
  class Song < Disposable::Facade
    facades Track
    # has_one :album
    # rename_options

    extend Build # do ... end instead of ClassMethods.
    #include Disposable::Facade::ActiveRecord

    module InstanceMethods
      # DISCUSS: this could be initializer do .. end
      def initialize(options)
        options[:title ] = options.delete(:name)
        super
      end
    end
    module ClassMethods

    end
  end

  #it { Track.facade(Song).new(:name => "Bombs Away").title.must_equal "Bombs Away" }
  it { Song.build(:name => "Bombs Away").title.must_equal "Bombs Away" }
  # it "what" do
  #   Song.build(:name => "Bombs Away").facade(Song).is_a?(Track).must_equal true
  # end
end