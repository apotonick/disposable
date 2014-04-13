require 'test_helper'

require 'active_record'
class Album < ActiveRecord::Base
  has_many :songs
end

class Song < ActiveRecord::Base
  belongs_to :album
end

ActiveRecord::Base.establish_connection(
  :adapter => "sqlite3",
  :database => "#{Dir.pwd}/database.sqlite3"
)

# ActiveRecord::Schema.define do
#   create_table :songs do |table|
#     table.column :title, :string
#     table.column :album_id, :integer
#     table.timestamps
#   end

#    create_table :albums do |table|
#     table.column :name, :string
#     table.timestamps
#   end
# end


require 'disposable/twin'

class TwinTest < MiniTest::Spec
  module Model
    Song  = Struct.new(:id, :title, :album)
    Album = Struct.new(:id, :name)
  end

  class Song < Disposable::Twin
    property :id # DISCUSS: needed for #save.
    property :title
    property :album, setter: lambda { |v, args| self.album=(Album.from(v)) }, :twin => true

    model Model::Song
  end

  class Album < Disposable::Twin
    property :id # DISCUSS: needed for #save.
    property :name
  end


  describe "::new" do # TODO: this creates a new model!
    subject { Song.new }

    it { subject.title.must_equal nil }
    it { subject.album.must_equal nil }
  end


  describe "::new with arguments" do
    subject { Song.new("title" => "Broken") }

    it { subject.title.must_equal "Broken" }
    # it { subject.album.must_equal nil }
  end


  describe "::new with :symbols" do
    subject { Song.new(:title => "Broken") }

    it { subject.title.must_equal "Broken" }
    # it { subject.album.must_equal nil }
  end


  # DISCUSS: make ::from private.
  describe "::from" do
    let (:song) { Model::Song.new(1, "Broken", album) }
    let (:album) { Model::Album.new(2, "The Process Of  Belief") }

    subject { Song.from(song) }

    it { subject.title.must_equal "Broken" }
    it { subject.album.must_be_kind_of Album }
    it { subject.album.name.must_equal album.name }
  end


  # ActiveRecord interface:
end

class TwinActiveRecordTest < MiniTest::Spec
  class Song < Disposable::Twin
    property :id
    property :title
    property :album, setter: lambda { |v, args| self.album=(Album.from(v)) }, :twin => true

    model ::Song
  end

  class Album < Disposable::Twin
    property :id
    property :name
  end


  describe "::find" do
    let (:song_model) { ::Song.create(:title => "Savage") }
    subject { Song.find(song_model.id) }

    it { subject.id.must_equal song_model.id }
    it { subject.title.must_equal "Savage" }
    it { subject.album.must_equal nil }
  end



  describe "::save, nested not set" do
    subject { Song.new(:title => "1.80 Down") }
    before { subject.save }

    it { ::Song.find(subject.id).attributes.slice("id", "title").
      must_equal({"id" => subject.id, "title" => "1.80 Down"}) }
  end

  describe "::save, nested present" do
    let (:song) { ::Song.new(:title => "Broken", :album => album) }
    let (:album) { ::Album.new(:name => "The Process Of  Belief") }

    subject { Song.from(song) }

    before { subject.save } # propagate album.save

    it { ::Song.find(subject.id).attributes.slice("id", "title").
      must_equal({"id" => subject.id, "title" => "Broken"})

      ::Song.find(subject.id).album.must_equal album
    }
  end
end


class TwinDecoratorTest < MiniTest::Spec
  subject { TwinTest::Song.representer_class }

  it { subject.twin_names.must_equal ["album"] }
end

# from is as close to from_hash as possible
# there should be #to in a perfect API, nothing else.


# should #new create empty associated models?
