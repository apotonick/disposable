# Disposable



## Twin

`Twin`s implement light-weight domain objects that contain business logic - no persistance logic. They have read- and write access to a persistant object (or a composition of those) and expose a sub-set of accessors to that persistant "brother", making it a "data mapper-like phantom".

Being designed to wrap persistant objects, a typical "brother" class could be an ActiveRecord one.

```ruby
class Song < ActiveRecord::Base
  belongs_to :album
end
```

You don't wanna work with that persistant brother directly anymore. A twin will wrap it and indirect domain from persistance.

The twin itself has a _ridiculous_ simple API.

```ruby
class Twin::Song < Disposable::Twin
  model ::Song                  # the persistant ActiveRecord brother class

  property :title
  property :album, twin: Album  # a nested twin.
```


### Creation

You can create fresh, blank-slate twins yourself. They will create a new persistant object automatically.

```ruby
song = Twin::Song.new(title: "Justified Black Eye")

#=> #<Twin::Song title: "Justified Black Eye">
```

This doesn't involve any database operations at all.


### Creation Using Finders

(to be implemented)
Every `Twin` subclass exposes all finders from the brother class. However, instances from the persistance layer are automatically twin'ed.

```ruby
song = Twin::Song.find(1)

#=> #<Twin::Song title: "Already Won" album: #<Twin::Album>>
```


### Read And Write Access

All attributes declared with `property` are exposed on the twin.

```ruby
song.title #=> "Already Won"

song.album.name #=> "The Songs of Tony Sly: A Tribute"
```

Note that writing to the twin **does not** change any state on the persistant brother.

```ruby
song.title = "Still Winning" # no change on Song, no write to DB.
```


### Saving

Calling `#save` will sync all properties to the brother object and advice the persistant brother to save. This works recursively, meaning that nested twins will do the same with their pendant.

```ruby
song.save # write to DB.
```

* Twins don't know anything about the underlying persistance layer.
* Lazy-loading



## To be documented properly

Facade existing (model) class
where to decorate old instances from collections?
  option.invoice_template => .items



class Invoice
	class Option
	  facades InvoiceOption

	  collection :items, original => :invoice_template
	  	def items invoice_template.collect ..
	  - or: opt.invoice_tempate.facade.

	end


Why facades?
you don't wanna add code to existing shit
transparently change the API
you don't have to worry about what's happening in the underlying pile of shit (GstCalculations module), you only correct the API on top of it
no inheritance, composition whereever possible (interfaces between layers)
optional, still use old assets
don't/step-wise change existing "running" code

you basically don't change existing code but build extracted components on top of your legacy app

* facades
* overriding public methods in facade
* temporary Refinements

* steps of refactoring


"partial refactoring"
"explicit refactoring"


* make it simple to split existing model into smaller (reducing validations etc)
* mark dead code
* by explicit use of `facade` you can track "dirt"

* rename options => DSL

TODO: Write a gem description
* generator for Facades
loading of facades?
location of facades? i wanna have Facade::Client, not facades/ClientFacade.
FACADE keeps all configuration in one place (like a new has_many), also you can track which methods you actually need in your data model. this wouldn't be possible that easy with inheritance.

Facadable#facade
Facade#facaded


idea: collect # REFAC lines


running with Rails 2.3->4.0, 1.8.7 ..as that makes sense


## Refinement

injected into instance _after_ construction

## Build



FacadeClass
  extend Build

  module ClassMethods
    def initializer
    def another_class_method # FIXME: does that work?

make anonymous class, allow overriding initializer and (works?) add class methods.


## Installation

Add this line to your application's Gemfile:

    gem 'disposable'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install disposable

## Usage

TODO: Write usage instructions here

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
