require "disposable/version"

module Disposable
  autoload :Composition,  "disposable/composition"
  autoload :Expose,       "disposable/expose"
end

# if defined?(ActiveRecord)
#   require 'disposable/facade/active_record'
# end

require "disposable/twin"