require 'disposable'
require 'minitest/autorun'

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
end

class Song < ActiveRecord::Base
  belongs_to :artist
end

class Album < ActiveRecord::Base
  has_many :songs
end

ActiveRecord::Base.establish_connection(
  :adapter => "sqlite3",
  :database => "#{Dir.pwd}/database.sqlite3"
)