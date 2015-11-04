class Disposable::Twin
  class Definition < Declarative::Definitions::Definition
    def getter
      self[:name]
    end

    def setter
      "#{self[:name]}="
    end
  end

  module DefinitionsEach
    def each(options={})
      return self unless block_given?

      super() do |dfn|
        next if options[:exclude]    and options[:exclude].include?(dfn[:name])
        next if options[:scalar]     and dfn[:collection]
        next if options[:collection] and ! dfn[:collection]
        next if options[:twin]       and ! dfn[:nested]

        yield dfn
      end

      self
    end
  end
end