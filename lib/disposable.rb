require "disposable/version"

module Disposable
  autoload :Composition,  'disposable/composition'
end

# if defined?(ActiveRecord)
#   require 'disposable/facade/active_record'
# end

require "disposable/twin"