module Disposable::Twin::Option
  def self.included(base)
    base.extend ClassMethods
  end

  module ClassMethods
    def option(name, options={})
      property(name, options.merge(:readable => false))
    end
  end
end