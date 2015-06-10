module Disposable::Twin::Callback
  class Runner
    def initialize(twin)
      @twin = twin
    end

    def on_add # how to call it once, for "all"?
      @twin.added.each do |item|
        yield item #if item.changed?(:persisted?) # after_create
      end
    end

    def on_update
      twins = [@twin]
      twins = @twin if @twin.is_a?(Array) # FIXME: FIX THIS, OF COURSE.

      twins.each do |twin|
        next unless twin.persisted? # only persisted can be updated.
        next if twin.changed?(:persisted?) # that means it was created.
        next unless twin.changed?
        yield twin
      end
    end

    def on_create
      twins = [@twin]
      twins = @twin if @twin.is_a?(Array) # FIXME: FIX THIS, OF COURSE.

      twins.each do |twin|
        next unless twin.changed?(:persisted?) # this has to be flipped.
        yield twin
      end
    end
  end
end