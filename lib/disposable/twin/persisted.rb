# Keeps the #persisted? property synced with the model's.
module Disposable::Twin::Persisted
  def self.included(includer)
    includer.property :persisted?, writeable: false
  end

  def save!(*)
    super.tap do
      send "persisted?=", model.persisted?
    end
  end
end