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