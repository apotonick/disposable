require "disposable/version"
require "disposable/twin"

module Disposable
  class Twin
    autoload :Composition,  "disposable/twin/composition"
    autoload :Expose,       "disposable/twin/composition"
  end
end