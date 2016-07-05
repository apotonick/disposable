require "uber/delegates"

module Disposable::Twin::Property
  module Unnest
    # TODO: test that nested properties options are "unnested", too, e.g. populator.
    def self.included(includer)
      includer.send(:include, Uber::Delegates)
    end

    def unnest(name, options)
      from = options.delete(:from)
      # needed to make reform process this field.
      property(name, virtual: true, _inherited: true)
      delegates from, name, "#{name}="
    end
  end
end
