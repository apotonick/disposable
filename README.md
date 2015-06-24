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

Twins are only # FIXME % slower than AR alone.

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

## With Representers

they indirect data, the twin's attributes get assigned without writing to the persistence layer, yet.

## With Contracts

## Collections

Define collections using `::collection`.

```ruby
class AlbumTwin < Disposable::Twin
  collection :songs do

  end
```

### API

The API is identical to `Array` with the following additions.

* `#<<(model)` adds item, wraps it in twin and tracks it via `#added`.
* `#insert(i, model)`, see `#<<`.
* `#delete(twin)`, removes twin from collection and tracks via `#deleted`.
* `#destroy(twin)`, removes twin from collection and tracks via `#deleted` and `#to_destroy` for destruction in `#save`.

### Semantics

Include `Twin::Collection::Semantics`.

Semantics are extensions to the pure Ruby array behavior and designed to deal with persistence layers like ActiveRecord or ROM.

* `#save` will call `destroy` on all models marked for destruction in `to_destroy`. Tracks destruction via `#destroyed`.


## Imperative Callbacks

Note: [Chapter 8 of the Trailblazer](http://leanpub.com/trailblazer) book is dedicated to callbacks and discusses them in great detail.

Callbacks use the fact that twins track state changes. This allows to execute callbacks on certain conditions.

```ruby
Callback.new(twin).on_create { |twin| .. }
Callback.new(twin.songs).on_add { |twin| .. }
Callback.new(twin.songs).on_add { |twin| .. }
```

It works as follows.

1. Twins track state changes, like _"item added to collection (`on_add`)"_ or _"property changed (`on_change`)"_.
2. You decide when to invoke one or a group of callbacks. This is why there's no `before_save` and the like anymore.
3. You also decide _what_ events to consider by calling the respective events only, like `on_add`.
4. The `Callback` will now find out which properties of the twin are affected and exectue your passed code for each of them.

This is called _Imperative Callback_ and the opposite of what you've learned from Rails.

By inversing the control, we don't need `before_` or `after_`. This is in your hands now and depends on where you invoke your callbacks.

## Events

The following events are available in `Callback`.

Don't confuse that with event triggering, though! Callbacks are passive, calling an event method means the callback will look for twins that have tracked the respective event (e.g. an twin has `change`d).

* `on_update`: Invoked when the underlying model was persisted, yet, at twin initialization and attributes have changed since then.
* `on_add`: For every twin that has been added to a collection.
* `on_add(:create)`: For every twin that has been added to a collection and got persisted. This will only pick up collection items after `sync` or `save`.

* `on_delete`: For every item that has been deleted from a collection.
* `on_destroy`: For every item that has been removed from a collection and physically destroyed.

* `on_change`: For every item that has changed attributes. When `persisted?` has flippend, this will be triggered, too.
* `on_change(:email)`: When the scalar field changed.


## Callback Groups

In order to simplify grouping callbacks and allowing a nested map we got `Callback::Group`.

```ruby
class AfterSave < Disposable::Callback::Group
  on_change :expire_cache!

  collection :songs do
    on_add :notify_album!
    on_add :reset_song!
  end

  on_update :rehash_name!, property: :title

  property :artist do
    on_change :sing!
  end
end
```

Calling that group on a twin will invoke all callbacks that apply, in the order they were added.

```ruby
AfterSave.new(twin).(context: self)
```

Methods like `:sing!` will be invoked on the `:context` object. Likewise, nested properties will be retrieved by simply calling the getter on the twin, like `twin.songs`.

Again, only the events that match will be invoked. If the top level twin hasn't changed, `expire_cache!` won't be invoked. This works by simply using `Callback` under the hood.

## Callback Inheritance

You can inherit groups, add and remove callbacks.

```ruby
class EnhancedAfterSave < AfterSave
  on_change :redo!

  collection :songs do
    on_add :rewind!
  end

  remove! :on_change, :expire_cache!
end
```

The callbacks will be _appended_ to the existing chain.

Instead of appending, you may also refine existing callbacks.

```ruby
class EnhancedAfterSave < AfterSave
  collection :songs, inherit: true do
    on_delete :rewind!
  end
end
```

This will add the `rewind!` callback to the `songs` property, resulting in the following chain.

```ruby
collection :songs do
    on_add    :notify_album!
    on_add    :reset_song!
    on_delete :rewind!
  end
```

## Overriding Accessors

super

## Used In

* [Reform](https://github.com/apotonick/reform) forms are based on twins and add a little bit of form decoration on top. Every nested form is a twin.
* [Trailblazer](https://github.com/apotonick/trailblazer) uses twins as decorators and callbacks in operations to structure business logic.