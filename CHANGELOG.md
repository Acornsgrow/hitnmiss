# ChangeLog

The following are lists of the notable changes included with each release.
This is intended to help keep people informed about notable changes between
versions, as well as provide a rough history.

#### Next Release

* Change `InMemoryDriver` to return `Hitnmiss::Driver::Hit` and
  `Hitnmiss::Driver::Miss` instances.
* Change driver interface to require `<#driver instance>.get` method to return a
  `Hitnmiss::Driver::Hit` instance or a `Hitnmiss::Driver::Miss` instance
* Add `Hitnmiss::Driver::Miss` class
* Add `Hitnmiss::Driver::Hit` class
* Change private methods `get`, `get_all` to `fetch` & `fetch_all`
* Change public API method `fetch(*args)` to `get(*args)`

#### v0.3.0

* Changed class style interface to object style interface
* Fixed `InMemoryDriver#all` to return values not hash of value & expiration
* Add return values to Public API Documentation examples

#### v0.2.0

* Renamed `Repository.prime_cache` to `Repository.prime`
* Added `Repository.prime_all` to prime entire repository
* Renamed `Repository.perform` to `Repository.get`
* Added `Repository.get_all` for `Repository.prime_all`
* Added `Repository.all` to get all cached values
* Added `Repository.delete` to delete a cached value
* Added `Repository.clear` to clear all cached values
* Added `Driver#all` interface to get all cached values
* Added `Driver#delete` interface to delete a cached value
* Added `Driver#clear` interface to clear all cached values
* Changed `InMemoryDriver` to implement `#all`, `#delete`, and `#clear`

#### v0.1.2

* Fix fetching cached boolean `false` value

#### v0.1.1

* Make the in memory driver threadsafe

#### v0.1.0

* Added driver registry to centrally manage instantiated drivers
* Add initial Minimum Viable Product version of the library
