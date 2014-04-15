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


class TwinActiveRecordTest < MiniTest::Spec
  module Twin
    class Album < Disposable::Twin
      property :id
      property :name

      model ::Album
    end

    class Song < Disposable::Twin
      property :id
      property :title
      property :album, :twin => Album#, representable: true  #, setter: lambda { |v, args| self.album=(Album.from(v)) }

      model ::Song
    end
  end



  describe "::find" do
    let (:song_model) { ::Song.create(:title => "Savage") }
    subject { Twin::Song.find(song_model.id) }

    it { subject.id.must_equal song_model.id }
    it { subject.title.must_equal "Savage" }
    it { subject.album.must_equal nil }
  end



  describe "::save, nested not set" do
    let (:twin) { Twin::Song.new(:title => "1.80 Down") }
    before { twin.save }
    subject { ::Song.find(twin.id) }

    it { subject.attributes.slice("id", "title").
      must_equal({"id" => subject.id, "title" => "1.80 Down"}) }

    it { subject.album.must_equal nil }
  end


  describe "::save, nested present" do
    let (:song) { ::Song.new(:title => "Broken", :album => album) }
    let (:album) { ::Album.new(:name => "The Process Of  Belief") }

    let(:twin) { Twin::Song.from(song) }

    before { twin.save } # propagate album.save

    subject { ::Song.find(twin.id) }

    it { subject.attributes.slice("id", "title").
      must_equal({"id" => subject.id, "title" => "Broken"}) }

    it { subject.album.must_equal album }
  end


  describe "::save, nested new" do
    let(:twin) { Twin::Song.new(:title => "How It Goes", :album => Twin::Album.new(:name => "Billy Talent")) }

    before { twin.save } # propagate album.save

    subject { ::Song.find(twin.id) }

    it {
      subject.attributes.slice("id", "title").
      must_equal({"id" => subject.id, "title" => "How It Goes"}) }

    it { subject.album.attributes.slice("name").must_equal("name" => "Billy Talent") }
  end
end