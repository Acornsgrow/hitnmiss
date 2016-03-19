# ChangeLog

The following are lists of the notable changes included with each release.
This is intended to help keep people informed about notable changes between
versions, as well as provide a rough history.

#### Next Release

* Changed: Repository and BackgroundRefreshRepository to use new Entity
* Changed: in-memory driver to support `last_modified`
* Changed: `Hitnmiss::Entity` to use keyword args
* Added: `last_modified` to `Hitnmiss::Entity`
* Added: `last_modified` to `Hitnmiss::Driver::Hit`
* Changed: `UnregistrdDriver` to `UnregisteredDriver`
* Added: `Hitnmiss::BackgroundRefreshRepository` to enable backround refresh
* Added: `updated_at` support to the in-memory driver
* Added: `fingerprint` support to the in-memory driver
* Added: `get_from_cache` private method to Repository
* Changed: Repository to use new driver set interface
* Changed: in-memory driver set, setnoexp to the new driver interface set method
* Changed: `set` method of driver interface to take key and entity
* Removed: `setnoexp` method from driver interface
* Added: `fingerprint` to `Hitnmiss::Entity`
* Added: `fingerprint` and `updated_at` attributes to `Hitnmiss::Driver::Hit`
* Added: `setnoexp` method to the in-memory driver
* Added: `setnoexp` method to driver interface

#### v1.0.0

* Changed version to 1.0 since the api is stable

#### v0.4.0

* Changed `InMemoryDriver` to return `Hitnmiss::Driver::Hit` and
  `Hitnmiss::Driver::Miss` instances.
* Changed driver interface to require `<#driver instance>.get` method to return a
  `Hitnmiss::Driver::Hit` instance or a `Hitnmiss::Driver::Miss` instance
* Added `Hitnmiss::Driver::Miss` class
* Added `Hitnmiss::Driver::Hit` class
* Changed private methods `get`, `get_all` to `fetch` & `fetch_all`
* Changed public API method `fetch(*args)` to `get(*args)`

#### v0.3.0

* Changed class style interface to object style interface
* Fixed `InMemoryDriver#all` to return values not hash of value & expiration
* Added return values to Public API Documentation examples

#### v0.2.0

* Changed `Repository.prime_cache` to `Repository.prime`
* Added `Repository.prime_all` to prime entire repository
* Changed `Repository.perform` to `Repository.get`
* Added `Repository.get_all` for `Repository.prime_all`
* Added `Repository.all` to get all cached values
* Added `Repository.delete` to delete a cached value
* Added `Repository.clear` to clear all cached values
* Added `Driver#all` interface to get all cached values
* Added `Driver#delete` interface to delete a cached value
* Added `Driver#clear` interface to clear all cached values
* Changed `InMemoryDriver` to implement `#all`, `#delete`, and `#clear`

#### v0.1.2

* Fixed fetching cached boolean `false` value

#### v0.1.1

* Changed the InMemoryDriver to be threadsafe

#### v0.1.0

* Added driver registry to centrally manage instantiated drivers
* Added initial Minimum Viable Product version of the library
