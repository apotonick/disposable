require 'disposable'
require 'minitest/autorun'

class Track
  def initialize(options={})
    @title = options[:title]
  end

  attr_reader :title
end
