class Disposable::Twin::PropertyProcessor
  def initialize(definition, twin)
    @definition, @twin = definition, twin
  end

  def call(&block)
    if @definition[:collection]
      collection!(&block)
    else
      property!(&block)
    end
  end

private
  def collection!
    arr = @twin.send(@definition.getter).collect { |nested_twin| yield(nested_twin) }
  end
  def property!
    twin = @twin.send(@definition.getter) or return nil
    nested_model = yield(twin)
  end
end