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
    it { subject.album.id.wont_equal nil } # FIXME: this only works because song is saved after album.
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


class TwinActiveRecordAsTest < MiniTest::Spec
  module Twin
    class Album < Disposable::Twin
      property :id
      property :name, :as => :album_name

      model ::Album
    end

    class Song < Disposable::Twin
      property :id
      property :title, :as => :song_title
      property :album, :twin => Album, :as => :record

      model ::Song
    end
  end


  describe "::from" do
     # (existing models)
    let (:song) { ::Song.new(:title => "Broken", :album => album) }
    let (:album) { ::Album.new(:name => "The Process Of Belief") }

    let(:twin) { Twin::Song.from(song) }

    it { twin.song_title.must_equal "Broken" }
    it { twin.record.album_name.must_equal "The Process Of Belief" }
  end


  describe "#save" do
    # existing models
    let (:song) { ::Song.new(:title => "Broken", :album => album) }
    let (:album) { ::Album.new(:name => "The Process Of  Belief") }

    let(:twin) { Twin::Song.from(song) }

    before do
      twin.song_title = "Emo Boy"
      twin.record.album_name = "Rode Hard And Put Away Wet"

      twin.save
    end

    let (:ar_song) { ::Song.find(twin.id) }
    let (:ar_album) { ar_song.album }

    it { ar_song.attributes.slice("id", "title").
      must_equal({"id" => ar_song.id, "title" => "Emo Boy"}) }

    it { ar_album.must_equal album }
    it("xxx") { ar_album.name.must_equal "Rode Hard And Put Away Wet" }
    it { ar_album.id.wont_equal nil } # FIXME: this only works because song is saved after album.
  end

end
