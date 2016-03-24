[![Build Status](https://travis-ci.com/Acornsgrow/hitnmiss.svg?token=GGEgqzL4zt7sa3zVgspU&branch=master)](https://travis-ci.com/Acornsgrow/hitnmiss)
[![Code Climate](https://codeclimate.com/repos/567a3c30bd3f3b63510017dd/badges/e979a32e79ec12d35896/gpa.svg)](https://codeclimate.com/repos/567a3c30bd3f3b63510017dd/feed)
[![Test Coverage](https://codeclimate.com/repos/567a3c30bd3f3b63510017dd/badges/e979a32e79ec12d35896/coverage.svg)](https://codeclimate.com/repos/567a3c30bd3f3b63510017dd/coverage)
[![Issue Count](https://codeclimate.com/repos/567a3c30bd3f3b63510017dd/badges/e979a32e79ec12d35896/issue_count.svg)](https://codeclimate.com/repos/567a3c30bd3f3b63510017dd/feed)

# Hitnmiss

Hitnmiss is a Ruby gem that provides support for using the Repository
pattern for read-through, write-behind caching in a thread-safe way. It
is built heavily around using POROs (Plain Old Ruby Objects). This means
it is intended to be used with all kinds of Ruby applications from plain
Ruby command line tools, to framework (Rails, Sinatra, Rack, Hanami,
etc.) based web apps, etc.

Having defined repositories for accessing your caches aids in a number of ways.
First, it centralizes cache key generation.  Secondly, it centralizes &
standardizes access to the cache rather than having code spread across your app
duplicating key generation and access. Third, it provides clean separation
between the cache persistence layer and the business representation.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'hitnmiss'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install hitnmiss

## Define/Mixin a Repository

Before you can use Hitnmiss to manage cache you first need to define a
cache repository. This is done by defining a class for your repository
and mixing the appropriate repository module in using `include`.

Below, are explanations of the **Standard Repository** and the **Background
Refresh Repository** so that you can decide which one fits your needs as well as
learn how to use them.

### Standard Repository

The standard repository module, `Hitnmiss::Repository`, fits the most common
caching use case, the "Expiration Model". The "Expiration Model" is a caching
model where a value gets cached with an associated expiration and when that
expiration is reached that value is no longer cached. This affects the app
behavior by having it pay the caching cost when it tries to get a value and it
has expired. The following is an example of creating a `MostRecentPrice` cache
repository for the "Expiration Model".

```ruby
class MostRecentPrice
  include Hitnmiss::Repository

  default_expiration 134 # expiration in seconds from when value cached
end
```

More often than not your caching use case will have a static/known
expiration that you want to use for all values that get cached. This is handled
for you by setting the `default_expiration` as seen in the example above.
**Note:** Hitnmiss also supports being able to have different expirations for
each cached value. You can learn more about this in the "Set Cache Source based
Expiration" section.

### Background Refresh Repository

Sometimes you don't have an expiration value and don't want cached values to
disappear. In these scenarios you want something to update the cache for you
based on some defined interval. When you use the
`Hitnmiss::BackgroundRefreshRepository` module and set the `refresh_interval`
as seen below, it prepares your repository to handle this scenario. This changes
the behavior where the app never experiences the caching cost as it is
continually managed for the app in the background based on the
`refresh_interval`.

```ruby
class MostRecentPrice
  include Hitnmiss::BackgroundRefreshRepository

  refresh_interval 60*5 # refresh interval in seconds
end
```

Once you have defined your Background Refresh Repository in order to get the
background process to update your cache you have to kick it off using the
`background_refresh(*args, swallow_exceptions: [])` method as seen in the
example below. The optional key word argument, `swallow_exceptions` defaults to
`[]`. If enabled it will prevent the specified exceptions, raised in the
`fetch(*args)` or `stale?(*args)` methods you defined, from killing the
background thread, and prevent the exceptions from making their way up to the
application. This is useful in scenarios where you want it to absorb say timeout
exceptions, etc. and continue trucking along. **Note:** Any other exceptions not
covered by the exceptions listed in the `swallow_exceptions` array will still be
raised up into the application.

```ruby
repository = MostRecentPrice.new
repository.background_refresh(store_id)
```

This model also has the added benefit that the priming of the cache in the
background refresh process is non-blocking. This means if you use this model the
consumer will not experience the priming of the cache like they would with the
Standard Repository's Expiration Model.

#### Staleness Checking

The Background Refresh Repository model introduces a new concept, Staleness
Checking. Staleness is checked during the background refresh process. The way it
works is if the cache is identified to be stale, then it primes the cache in the
background, if the cache is identified to NOT be stale, then it sleeps for
another `refresh_interval`.

The stale checker, `stale?(*args)`, defaults to an always stale value of `true`.
This causes the background refresh process to prime the cache every
`refresh_interval`.

If you want your cache implementation to be smarter and say validate a
fingerprint or last modified value against the source, you can do it simply by
overwriting the `stale?(*args)` method with your own staleness checking logic.
The following is an example of this.

```ruby
class MostRecentPrice
  include Hitnmiss::BackgroundRefreshRepository

  refresh_interval 60*5 # refresh interval in seconds

  def initialize
    @client = HTTPClient.new
  end

  def stale?(*args)
    hit_or_miss = get_from_cache(*args)
    if hit_or_miss.is_a?(Hitnmiss::Driver::Miss)
      return true
    elsif hit_or_miss.is_a?(Hitnmiss::Driver::Hit)
      url = "https://someresource.example.com/#{args[0]}/#{args[1]}/digest.json"
      res = @client.head(url)
      fingerprint = res.header['ETag'].first
      return false if fingerprint == hit_or_miss.fingerprint
      return true
    else
      raise Hitnmiss::Repository::UnsupportedDriverResponse.new("Driver '#{self.class.driver.inspect}' did not return an object of the support types (Hitnmiss::Driver::Hit, Hitnmiss::Driver::Miss)")
    end
  end
end
```

### Set a Repositories Cache Driver

Hitnmiss defaults to the provided `Hitnmiss::InMemoryDriver`, but if an alternate
driver is needed a new driver can be registered as seen below.

```ruby
# config/hitnmiss.rb
Hitnmiss.register_driver(:my_driver, SomeAlternativeDriver.new)
```

Once you have registered the new driver you can tell `Hitnmiss` what
driver to use for this particular repository. The following is an example
of how one would accomplish setting the repository driver to the driver
that was just registered.

```ruby
class MostRecentPrice
  include Hitnmiss::Repository

  driver :my_driver
end
```

This works exactly the same with the `Hitnmiss::BackgroundRefreshRepository`.

### Define Fetcher Methods

You may be asking yourself, "How does the cache value get set?" Well,
the answer is one of two ways.

* Fetching an individual cacheable entity
* Fetching all of the repository's cacheable entities

Both of these scenarios are supported by defining the `fetch(*args)`
method or the `fetch_all(keyspace)` method respectively in your cache
repository class. See the following example.

```ruby
class MostRecentPrice
  include Hitnmiss::Repository

  default_expiration 134

  private

  def fetch(*args)
    # - do whatever to get the value you want to cache
    # - construct a Hitnmiss::Entity with the value
    Hitnmiss::Entity.new('some value')
  end

  def fetch_all(keyspace)
    # - do whatever to get the values you want to cache
    # - construct a collection of arguments and Hitnmiss entities
    [
      { args: ['a', 'b'], entity: Hitnmiss::Entity.new('some value') },
      { args: ['x', 'y'], entity: Hitnmiss::Entity.new('other value') }
    ]
  end
end
```

The `fetch(*args)` method is responsible for obtaining the value that you want
to cache by whatever means necessary and returning a `Hitnmiss::Entity`
containing the value, and optionally an `expiration`, `fingerprint`, and
`last_modified`. **Note:** The `*args` passed into the `fetch(*args)` method
are whatever the arguments are that are passed into `prime` and `get` methods
when they are called. Defining the `fetch(*args)` method is **required** if you
want to be able to cache values or get cached values using the `prime` or `get`
methods.

If you wish to support priming the cache for an entire repository using
the `prime_all` method, you **must** define the `fetch_all(keyspace)`
method on the repository class. This method **must** return a collection
of hashes describing the `args` that would be used to get an entity
and the corresponding `Hitnmiss::Entity`. See example above.

#### Set Cache Source based Expiration

In some cases you might need to set the expiration to be a different
value for each cached value. This is generally needed when you get
information back from a remote entity in the `fetch(*args)` method and you
use it to compute the expiration. This for example could be via the `Expiration`
header in an HTTP response. Once you have the expiration for that
value you can set it by passing the expiration into the
`Hitnmiss::Entity` constructor as seen below. **Note:** The expiration
in the `Hitnmiss::Entity` will take precedence over the
`default_expiration`.

```ruby
class MostRecentPrice
  include Hitnmiss::Repository

  default_expiration 134

  private

  def fetch(*args)
    # - do whatever to get the value you want to cache
    # - construct a Hitnmiss::Entity with the value and optionally a
    #   result based expiration. If no result based expiration is
    #   provided it will use the default_expiration.
    Hitnmiss::Entity.new('some value', expiration: 235)
  end
end
```

#### Set Cache Source based Fingerprint

In some cases you might want to set the fingerprint for the cached value. Doing
so provides more flexibility to `Hitnmiss` in terms of determining staleness of
cache. A very common example of this would be if you are fetching something over
HTTP from the remote and the remote includes the `ETag` header. If you take the
value of the `ETag` header (a fingerprint) and you set it in the
`Hitnmiss::Entity` it can be used later on by `Hitnmiss` to aid in identifying
staleness. Once you have obtained the fingerprint by whatever means you can set
it by passing the fingerprint into the `Hitnmiss::Entity` constructor as seen
below.

```ruby
class MostRecentPrice
  include Hitnmiss::Repository

  default_expiration 134

  private

  def fetch(*args)
    # - do whatever to get the value you want to cache
    # - do whatever to get the fingerprint of the value you want to cache
    # - construct a Hitnmiss::Entity with the value and optionally a
    #   fingerprint.
    Hitnmiss::Entity.new('some value',
                         fingerprint: "63478adce0dd0fbc82ef4bb1f1d64193")
  end
end
```

#### Set Cache Source based Last Modified

In some cases you might want to set the `last_modified` value for a cached
value. Doing this provides more felxibility to `Hitnmiss` when trying to
determine staleness of a cached item. A common example of this would be if you
are fetching somthing over HTTP from a remote server and it includes the
`Last-Modified` entity header in the response. If you took the value of the
`Last-Modified` header and you set it in the `Hitnmiss::Entity` it can be used
later on by `Hitnmiss` to aid in identifying staleness. Once you have obtained
the `Last-Modified` value by whatever means you can set it by passing the
`last_modified` option into the `Hitnmiss::Entity` constructor as seen below.

```ruby
class MostRecentPrice
  include Hitnmiss::Repository

  default_expiration 134

  private

  def fetch(*args)
    # - do whatever to get the value you want to cache
    # - do whatever to get the last modified of the value you want to cache
    # - construct a Hitnmiss::Entity with the value and optionally a
    #   last_modified value.
    Hitnmiss::Entity.new('some value',
                         last_modified: "2016-04-15T13:00:00Z")
  end
end
```

## Usage

The following is a light breakdown of the various pieces of Hitnmiss and
how to get going with them after defining your cache repository.

### Priming an entity

Once you have defined the `fetch(*args)` method you can construct an
instance of your cache repository and use it. One way you might want to
use it is to force the repository to cache a value. This can be done
using the `prime` method as seen below.

```ruby
repository = MostRecentPrice.new
repository.prime(current_user.id) # => cached_value
```

### Priming the entire repository

You can use the `prime_all` method to prime the entire repository. **Note:**
The repository class must define the `fetch_all(keyspace)` method for this
to work. See the "Define Fetcher Methods" section above for details.

```ruby
repository = MostRecentPrice.new
repository.prime_all # => [cached values, ...]
```

### Getting a value

You can also use your cache repository to get a particular cached
value by doing the following.

```ruby
repository = MostRecentPrice.new
repository.get(current_user.id) # => cached_value
```

### Deleting a cached value

You can delete a cached value by calling the `delete` method with the
same arguments used to get it.

```ruby
repository = MostRecentPrice.new
# cache some values ex: repository.prime(current_user.id)
repository.delete(current_user.id)
```

### Clearing a repository

You can clear the entire repository of cached values by calling the
`clear` method.

```ruby
repository = MostRecentPrice.new
# cache some values ex: repository.prime(current_user.id)
repository.clear
```

## Development

After checking out the repo, run `bin/setup` to install dependencies.
Then, run `rake spec` to run the tests. You can also run `bin/console`
for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake
install`. To release a new version, update the version number in
`version.rb`, and then run `bundle exec rake release`, which will create
a git tag for the version, push git commits and tags, and push the
`.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at
https://github.com/Acornsgrow/hitnmiss. This project is intended to be a
safe, welcoming space for collaboration, and contributors are expected
to adhere to the [Contributor Covenant](http://contributor-covenant.org)
code of conduct.

## License

The gem is available as open source under the terms of the [MIT
License](http://opensource.org/licenses/MIT).
