class Disposable::Facade
  module ActiveRecord
    def is_a?(klass)
      # DISCUSS: should we use facade_options here for the class?
      klass == __getobj__.class or super
    end
  end
end