module Disposable::Twin::Save
  # Returns the result of that save invocation on the model.
  def save(options={}, &block)
    res = sync(&block)
    return res if block_given?

    save!(options)
  end

  def save!(options={})
    result = save_model

    self.class.bla.each do |dfn|
      next unless dfn[:twin]
      next if dfn[:save] == false
      # next if options_[:exclude].include?(dfn.name.to_sym)

      # model.send(dfn.setter, send(dfn.getter)) and next unless dfn[:twin]

      if dfn[:collection]
        arr = send(dfn.getter).collect { |nested_twin| nested_twin.save!({}) }
        # model.send(dfn.setter, arr) # FIXME: override this for different collection syncing.
      else
        next if send(dfn.getter).nil?
        nested_model = send(dfn.getter).save!({}) # sync.

        # model.send(dfn.setter, nested_model)
      end

    end

    result
  end

  def save_model
    model.save
  end
end
