# Disposable

_Provides domain objects on top of your ORM layer._

## Introduction

Disposable gives you "_Twins_" which are domain objects, decoupled from ActiveRecord, DataMapper or whatever ORM you use.

Twins are non-persistent domain objects. That is reflected in the name of the gem. However, they can read and write values from a persistent object.

Twins are an integral part of the "Trailblazer":https://github.com/apotonick/trailblazer architectural style which provides clean layering of concerns.

They provide a clean alternative to delegators that many projects use to separate domain and persistence and help you restricting the domain API.

## Why?

The goal is to have business logic sitting in twin classes, while your models (ideally) contain persistence configuration, only.

Beyond that, twins can be used in form objects, cells view models, representers, contracts, and actually any Ruby code :)

Twins may contain validations, nevertheless, in Trailblazer, validations (or "Contracts") sit one layer above. They still can be part of your domain, though.

## Twin

Twins implement light-weight domain objects that contain business logic - no persistance logic. They have read- and write access to a persistent object (or a composition of those) and expose a sub-set of accessors to that persistent "brother", making it a "data mapper-like phantom".

Being designed to wrap persistent objects, a typical "brother" class could be an ActiveRecord one.

```ruby
class Song < ActiveRecord::Base
  belongs_to :album
end
```

You don't wanna work with that persistent brother directly anymore. A twin will wrap it and indirect domain from persistance.

The twin itself has a _ridiculous_ simple API.

```ruby
class Twin::Song < Disposable::Twin
  model ::Song                  # the persistent ActiveRecord brother class

  property :title
  property :album, twin: Album  # a nested twin.
```


### Creation

You can create fresh, blank-slate twins yourself. They will create a new persistent object automatically.

```ruby
song = Twin::Song.new(title: "Justified Black Eye")

#=> #<Twin::Song title: "Justified Black Eye">
```

This doesn't involve any database operations at all.


### Finders

You can use any finder/scope defined in your model to create twins.

Since `::find` is pretty common, it is defined directly on the twin class.

```ruby
song = Twin::Song.find(1)

#=> #<Twin::Song title: "Already Won" album: #<Twin::Album>>
```

This invokes the actual finder method on the model class. Every found model will simply be wrapped in its twin.


Any other scope or finder can be called on `finders`.

```ruby
song = Twin::Song.finders.where(name: "3 O'Clock Shot")

#=> [#<Twin::Song title: "3 O'Clock Shot" album: #<Twin::Album>>]
```



### Read And Write Access

All attributes declared with `property` are exposed on the twin.

```ruby
song.title #=> "Already Won"

song.album.name #=> "The Songs of Tony Sly: A Tribute"
```

Note that writing to the twin **does not** change any state on the persistent brother.

```ruby
song.title = "Still Winning" # no change on Song, no write to DB.
```


### Saving

Calling `#save` will sync all properties to the brother object and advice the persistent brother to save. This works recursively, meaning that nested twins will do the same with their pendant.

```ruby
song.save # write to DB.
```

## Notes

* Twins don't know anything about the underlying persistance layer.
* Lazy-loading TBI
