# ChangeLog

The following are lists of the notable changes included with each release.
This is intended to help keep people informed about notable changes between
versions, as well as provide a rough history.

#### Next Release

* Changed `Repository.prime_cache` to prime entire repository
* Added `Repository.prime_entity_cache` to prime an individual entity
* Renamed `Repository.perform` to `.fetch_cacheable_entity`
* Added `Repository.fetch_cacheable_entities` for `.prime_cache`
* Added `Repository.all` to get all cached values
* Added `Repository.delete` to delete a cached value
* Added `Repository.clear` to clear all cached values
* Added `Driver#all` interface to get all cached values
* Added `Driver#del` interface to delete a cached value
* Added `Driver#clear` interface to clear all cached values
* Changed `InMemoryDriver` to implement `#all`, `#del`, and `#clear`

#### v0.1.2

* Fix fetching cached boolean `false` value

#### v0.1.1

* Make the in memory driver threadsafe

#### v0.1.0

* Added driver registry to centrally manage instantiated drivers
* Add initial Minimum Viable Product version of the library
