# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'disposable/version'

Gem::Specification.new do |spec|
  spec.name          = "disposable"
  spec.version       = Disposable::VERSION
  spec.authors       = ["Nick Sutterer"]
  spec.email         = ["apotonick@gmail.com"]
  spec.description   = %q{Decorators on top of your ORM layer.}
  spec.summary       = %q{Decorators on top of your ORM layer with change tracking, collection semantics and nesting.}
  spec.homepage      = "https://github.com/apotonick/disposable"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "uber"
  spec.add_dependency "representable", ">= 2.2.3", "< 2.4.0"

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "minitest"
  spec.add_development_dependency "activerecord"
  spec.add_development_dependency "sqlite3"
  spec.add_development_dependency "virtus"
  # spec.add_development_dependency "database_cleaner"
end
