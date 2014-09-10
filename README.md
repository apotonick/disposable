# Disposable

_Decorators on top of your ORM layer._

## Introduction

Disposable gives you "_Twins_" which are domain objects, decoupled from ActiveRecord, DataMapper or whatever ORM you use.

Twins are non-persistent domain objects. That is reflected in the name of the gem. However, they can read and write values from a persistent object.

Twins are an integral part of the [Trailblazer](https://github.com/apotonick/trailblazer) architectural style which provides clean layering of concerns.

They give you an encapsulated alternative to delegators that many projects use to separate domain and persistence and help you restricting the domain API.

## Why?

The goal is to have business logic sitting in twin classes, while your models (ideally) contain persistence configuration, only.

Beyond that, twins can be used in form objects, cells view models, representers, contracts, and actually any Ruby code :)

Twins may contain validations, nevertheless, in Trailblazer, validations (or "Contracts") sit one layer above. They still can be part of your domain, though.

## Twin

Twins implement light-weight decorators objects with a unified interface. They map objects and compositions of objects, along with optional hashes to inject additional data.

Let me show you what I mean.

```ruby
song = Song.create(title: "Savior", length: 242)
``

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

## Writing

## Renaming

## Compositions

