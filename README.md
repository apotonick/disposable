# Disposable


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


Facadable#facade
Facade#facaded

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
