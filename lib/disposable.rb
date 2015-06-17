require "disposable/version"

# if defined?(ActiveRecord)
#   require 'disposable/facade/active_record'
# end

require "disposable/twin"

module Disposable
  class Twin
    autoload :Composition,  "disposable/twin/composition"
    autoload :Expose,       "disposable/twin/composition"
  end
end