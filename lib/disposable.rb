require "disposable/version"

module Disposable
  # Your code goes here...
  autoload :Twin, 'disposable/twin'
end

require "disposable/facade"

if defined?(ActiveRecord)
  require 'disposable/facade/active_record'
end
