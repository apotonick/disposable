module Disposable::Twin::Save
  # Returns the result of that save invocation on the model.
  def save(options={}, &block)
    res = sync(&block)
    return res if block_given?

    save!(options)
  end

  def save!(options={})
    result = save_model

    self.class.representer_class.each(twin: true) do |dfn|
      next if dfn[:save] == false

      # call #save! on all nested twins.
      PropertyProcessor.new(dfn, self).() { |twin| twin.save! }
    end

    result
  end

  def save_model
    model.save
  end



  class PropertyProcessor
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
end
