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
#   create_table :invoices do |table|
#     table.timestamps
#   end
# end

# ActiveRecord::Schema.define do
#   create_table :invoice_items do |table|
#     table.column :invoice_id, :string
#     table.timestamps
#   end
# end


require 'uber/inheritable_attr'
require 'representable/decorator'
require 'representable/hash'



class Disposable::Twin
  class Decorator < Representable::Decorator
    include Representable::Hash

    # DISCUSS: same in reform, is that a bug in represntable?
    def self.clone # called in inheritable_attr :representer_class.
      Class.new(self) # By subclassing, representable_attrs.clone is called.
    end
  end

  extend Uber::InheritableAttr
  inheritable_attr :representer_class
  self.representer_class = Class.new(Decorator)

  def self.property(name, *args, &block)
    attr_accessor name

    representer_class.property(name, *args, &block)
  end

  def self.from(model)
    from_hash(representer_class.new(model).to_hash)
  end

  def self.from_hash(options={})
    representer_class.new(new).from_hash(options)
  end
# def setup_fields(model)
#       representer = mapper.new(model).extend(Setup::Representer)

#       create_fields(representer.fields, representer.to_hash)
#     end
end


class TwinTest < MiniTest::Spec
  let (:album_struct) { Struct.new(:name) }
  let (:song_struct) { Struct.new(:id, :title, :album) }

  class Song < Disposable::Twin
    property :id
    property :title
    property :album, setter: lambda { |v, args| self.album=(Album.from(v)) }
  end

  class Album < Disposable::Twin
    property :name
  end


  describe "::from_hash" do
    subject { Song.from_hash }

    it { subject.title.must_equal nil }
    it { subject.album.must_equal nil }
  end


  describe "::from_hash with arguments" do
    subject { Song.from_hash("title" => "Broken") }

    it { subject.title.must_equal "Broken" }
    # it { subject.album.must_equal nil }
  end


  describe "::from" do
    let (:song) { song_struct.new(1, "Broken", album) }
    let (:album) { album_struct.new("The Process Of  Belief") }

    subject { Song.from(song) }

    it { subject.title.must_equal "Broken" }
    it { subject.album.must_be_kind_of Album }
    it { subject.album.name.must_equal album.name }
  end


  # describe "::find" do

  #   it { subject.title.must_equal "Broken" }
  #   it { subject.album.must_equal album }
  # end


  describe "::save" do
    it { ::Song.find(subject.id).attributes.must_equal({}) }
  end
end