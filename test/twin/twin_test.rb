require 'test_helper'


class TwinTest < MiniTest::Spec
  module Model
    Song  = Struct.new(:id, :title, :album)
    Album = Struct.new(:id, :name)
  end


  module Twin
    class Album < Disposable::Twin
      property :id # DISCUSS: needed for #save.
      property :name

      model Model::Album
    end

    class Song < Disposable::Twin
      property :id # DISCUSS: needed for #save.
      property :title
      property :album, :twin => Album #, setter: lambda { |v, args| self.album=(Album.from(v)) }

      model Model::Song
    end
  end


  describe "::new" do # TODO: this creates a new model!
    subject { Twin::Song.new }

    it { subject.title.must_equal nil }
    it { subject.album.must_equal nil }
  end


  describe "::new with arguments" do
    let (:album) { Twin::Album.new(:name => "30 Years") }
    subject { Twin::Song.new("title" => "Broken", "album" => album) }

    it { subject.title.must_equal "Broken" }
    it { subject.album.must_equal album }
    it { subject.album.name.must_equal "30 Years" }
  end


  describe "::new with :symbols" do
    subject { Twin::Song.new(:title => "Broken") }

    it { subject.title.must_equal "Broken" }
    it { subject.album.must_equal nil }
  end


  # DISCUSS: make ::from private.
  describe "::from" do
    let (:song) { Model::Song.new(1, "Broken", album) }
    let (:album) { Model::Album.new(2, "The Process Of  Belief") }

    subject {Twin::Song.from(song) }

    it { subject.title.must_equal "Broken" }
    it { subject.album.must_be_kind_of Twin::Album }
    it { subject.album.name.must_equal album.name }
  end
end


class TwinDecoratorTest < MiniTest::Spec
  subject { TwinTest::Twin::Song.representer_class.new(nil) }

  it { subject.twin_names.must_equal [:album] }
end

# from is as close to from_hash as possible
# there should be #to in a perfect API, nothing else.


# should #new create empty associated models?


class TwinAsTest < MiniTest::Spec
  module Model
    Song  = Struct.new(:title, :album)
    Album = Struct.new(:name)
  end


  module Twin
    class Album < Disposable::Twin
      property :record_name, :as => :name

      model Model::Album
    end

    class Song < Disposable::Twin
      property :name, :as => :title
      property :record, :twin => Album, :as => :album

      model Model::Song
    end
  end


  let (:record) { Twin::Album.new(:record_name => "Veni Vidi Vicous") }
  subject { Twin::Song.new(:name => "Outsmarted", :record => record) }


  describe "::new" do # TODO: this creates a new model!
    # the Twin exposes the as: API.
    it { subject.name.must_equal "Outsmarted" }
    it { subject.record.must_equal record }
  end

  # DISCUSS: should we test saving without AR? is that worth the hustle?
  # describe "#save" do
  #   before { subject.send(:model).instance_eval do
  #     def update_attributes(*)

  #     end
  #   end
  #   subject.save
  # }



  #   # before { subject.save }

  #   it { subject.name }
  # end
end


# TODO: test coercion!