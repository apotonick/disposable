module Disposable::Twin::Callback
  class Runner
    def initialize(twin)
      @twin = twin
    end

    def on_add(state=nil) # how to call it once, for "all"?
      @twin.added.each do |item|
        yield item if state.nil?
        yield item if item.changed?(:persisted?) && state == :created # :created # DISCUSS: should we really keep that?
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