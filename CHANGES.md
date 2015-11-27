# 0.1.15

* Restrict to Representable < 2.4.

# 0.1.14

* Allow to nil-out nested twins.

# 0.1.13

* Allow representable ~> 2.2.

# 0.1.12

* Added `Twin::for_collection`. Thanks to @timoschilling for the implementation.

# 0.1.11

* `:default` now accepts lambdas, too. Thanks to @johndagostino for implementing this.

# 0.1.10

* yanked.

# 0.1.9

* The `:twin` option is no longer evaluated at compile time, only inline twins are run through `::process_inline!`. This allows specifying twin classes in lambdas for lazy-loading, and recursive twins.

# 0.1.8

* Specifying a nested twin with `:twin` instead of a block now gets identically processed to the block.

# 0.1.7

* Removed Setup#merge_options! and hash merge as this is already been done in #setup_properties.
* Every property now gets set on the twin, even if `readable: false` is set.
* `:default` and `:virtual` now work together.
* Introduced `Setup#setup_property!`.

# 0.1.6

* Added `Default`.

# 0.1.5

* Correctly merge options from constructor into `@fields`.
* Add `:virtual` which is an alias for `readable: false, writeable: false`.
* Do not use getters with `SkipGetter` in `#sync{}`.

# 0.1.4

* Add `Twin::Coercion`.

# 0.1.3

* Fix `Composition#save`, it now returns true only if all models could be saved.
* Introduce `Callback::Group::clone`.

# 0.1.2

* Fix `Changed` which does not use the public reader to compare anymore, but the private `field_read`.

# 0.1.1

* Adding `Setup::SkipSetter` and `Sync::SkipGetter`.

# 0.1.0

* This is the official first serious release.

# 0.0.9

* Rename `:as` to `:from`. Deprecated, this will be removed in 0.1.0.

# 0.0.8

* Introduce the `Twin::Builder` module to easily allow creating a twin in a host object's constructor.

# 0.0.7

* Make disposable require representable 2.x.

# 0.0.6

* Add Twin::Option.

# 0.0.4

* Added `Composition#[]` to access contained models in favor of reader methods to models. The latter got removed. This allows mapping methods with the same name than the contained object.