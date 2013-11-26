require "disposable/version"

module Disposable
  # Your code goes here...
end

require "disposable/facade"

if defined?(ActiveRecord)
  require 'disposable/facade/active_record'
end
