# Disposable

_Decorators on top of your ORM layer._

## Introduction

Disposable gives you "_Twins_" which are domain objects, decoupled from ActiveRecord, DataMapper or whatever ORM you use.

Twins are non-persistent domain objects. That is reflected in the name of the gem. However, they can read and write values from a persistent object.

Twins are an integral part of the [Trailblazer](https://github.com/apotonick/trailblazer) architectural style which provides clean layering of concerns.

They give you an encapsulated alternative to delegators that many projects use to separate domain and persistence and help you restricting the domain API.

## Why?

The goal is to have one object that delegates reading and writing to underlying object(s). This is a fundamental concept for cells view models, representers, and reform form objects.

Twins may contain validations, nevertheless, in Trailblazer, validations (or "Contracts") sit one layer above. They still can be part of your domain, though.

## Twin

Twins implement light-weight decorators objects with a unified interface. They map objects, hashes, and compositions of objects, along with optional hashes to inject additional options.

Let me show you what I mean.

```ruby
song = Song.create(title: "Savior", length: 242)
```

## Definition

Twins need to define every field they expose.

```ruby
class Song::Twin < Disposable::Twin
  property :title
  property :length
  option   :good?
end
```

## Creation

You need to pass model and the optional options to the twin constructor.

```ruby
twin = Song::Twin.new(song, good?: true)
```

## Reading

This will create a composition object of the actual model and the hash.

```ruby
twin.title #=> "Savior"
twin.good? #=> true
```

You can also override `property` values in the constructor:

```ruby
twin = Song::Twin.new(song, title: "Plasticash")
twin.title #=> "Plasticash"
```

Let's talk about what happens to the actual model when setting values?

## Writing

It doesn't happen. The model is only queried when _reading_ values. Writing only happens in additional modules: Syncing and Saving is where the values held in the twin are written to the model.

## Renaming

## Structs

If you don't have a model but a simple hash, use `Struct`.

```ruby
class Song::Twin < Disposable::Twin
  include Struct
  property :title
  property :length
end
```

Note that a hash goes into the constructor now.

```ruby
twin = Song::Twin.new(title: "Savior", good?: true)
```


## Compositions

## Overriding Accessors

super

## Used In