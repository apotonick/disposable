require 'disposable'
require 'minitest/autorun'
require "pp"
require "representable/debug"

class Track
  def initialize(options={})
    @title = options[:title]
  end

  attr_reader :title
end


# require 'active_record'
# require 'database_cleaner'
# DatabaseCleaner.strategy = :truncation

require 'active_record'
class Artist < ActiveRecord::Base
  has_many :albums
end

class Song < ActiveRecord::Base
  belongs_to :artist
end

class Album < ActiveRecord::Base
  has_many :songs
  belongs_to :artist
end

ActiveRecord::Base.establish_connection(
  :adapter => "sqlite3",
  :database => ":memory:"
)

ActiveRecord::Schema.define do
  create_table :artists do |table|
    table.column :name, :string
    table.timestamps
  end
  create_table :songs do |table|
    table.column :title, :string
    table.column :artist_id, :integer
    table.column :album_id, :integer
    table.timestamps
  end
  create_table :albums do |table|
    table.column :name, :string
    table.column :artist_id, :integer
    table.timestamps
  end
end

module Disposable
  module Comparable
    def attributes(source)
      source.instance_variable_get(:@fields)
    end

    def ==(other)
      self.class == other.class and attributes(self) == attributes(other)
    end
  end

  module Saveable
    def save
      @saved = true
    end

    def saved?
      @saved
    end
  end
end

