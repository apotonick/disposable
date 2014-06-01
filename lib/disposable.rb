require "disposable/version"

module Disposable
  autoload :Twin,         'disposable/twin'
  autoload :Composition,  'disposable/composition'
end

# if defined?(ActiveRecord)
#   require 'disposable/facade/active_record'
# end
