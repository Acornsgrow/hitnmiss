[![Build Status](https://travis-ci.com/Acornsgrow/hitnmiss.svg?token=GGEgqzL4zt7sa3zVgspU&branch=master)](https://travis-ci.com/Acornsgrow/hitnmiss)
[![Code Climate](https://codeclimate.com/repos/567a3c30bd3f3b63510017dd/badges/e979a32e79ec12d35896/gpa.svg)](https://codeclimate.com/repos/567a3c30bd3f3b63510017dd/feed)
[![Test Coverage](https://codeclimate.com/repos/567a3c30bd3f3b63510017dd/badges/e979a32e79ec12d35896/coverage.svg)](https://codeclimate.com/repos/567a3c30bd3f3b63510017dd/coverage)
[![Issue Count](https://codeclimate.com/repos/567a3c30bd3f3b63510017dd/badges/e979a32e79ec12d35896/issue_count.svg)](https://codeclimate.com/repos/567a3c30bd3f3b63510017dd/feed)

# Hitnmiss

Hitnmiss is a Ruby gem that provides support for using the Repository
pattern for read-through, write-behind caching. It is built heavily
around using POROs (Plain Old Ruby Objects). This means it is intended
to be used with all kinds of Ruby applications from plain Ruby command
line tools, to framework (Rails, Sinatra, Rack, Hanami, etc.) based web
apps.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'hitnmiss'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install hitnmiss

## Usage

The following is a light breakdown of the various pieces of Hitnmiss and
how to get going with them.

### Define/Mixin Repository

Before you can use Hitnmiss to manage cache you first need to define a
cache repository. This is done by defining a class for your repository
and mixing `Hitnmiss::Repository` into it using `include`.

```ruby
# lib/cache_repositories/most_recent_price.rb
class MostRecentPrice
  include Hitnmiss::Repository
end
```

The value of having defined repositories for accessing your caches aids
in a number of ways. First, it centralizes cache key generation.
Secondly, it centralizes/standardizes access to the cache rather than
having code spread across your app duplicating key generation and
access. Third, it provides clean separation between the cache
persistence layer and the business representation.

###  Set a Repositories Cache Driver

Hitnmiss defaults to the `InMemoryDriver`, but if an alternate driver is
needed, or if a separate `InMemoryDriver` is required a new driver can be
registered

```ruby
# config/hitnmiss.rb
Hitnmiss.register_driver(:my_driver, Hitnmiss::InMemoryDriver.new)
```

Once you have registered a new driver you need to tell `Hitnmiss` what
driver to use for this particular repository. The following is an example
of how one would accomplish setting the repository driver to the driver we
just registered.

```ruby
# lib/cache_repositories/most_recent_price.rb
class MostRecentPrice
  include Hitnmiss::Repository

  driver :my_driver
end
```

### Set the Default Expiration

More often than not, your caching use case will have a static, known
expiration that would like to use all the time. In these scenarios you
can set the `default_expiration` to manage the expiration across the
entire repository. The following is an example of how one would do this.

```ruby
# lib/cache_repositories/most_recent_price.rb
class MostRecentPrice
  include Hitnmiss::Repository

  default_expiration 134
end
```

### Define Cache Source

You may be asking yourself, "How does the cache value get set?" Well,
the answer is one of two ways.

* Fetching an individual cacheable entity
* Fetching all of the repository's cacheable entities

Both of these scenarios are supported by defining the `get(*args)`
method and the `get_all(keyspace)` method respectively.  See the
following example.

```ruby
# lib/cache_repositories/most_recent_price.rb
class MostRecentPrice
  include Hitnmiss::Repository

  default_expiration 134

  def get(*args)
    # - do whatever to get the value you want to cache
    # - construct a Hitnmiss::Entity with the value
    Hitnmiss::Entity.new('some value')
  end

  def get_all(keyspace)
    # - do whatever to get the values you want to cache
    # - construct a collection of arguments and Hitnmiss entities
    [
      { args: ['a', 'b'], entity: Hitnmiss::Entity.new('some value') },
      { args: ['x', 'y'], entity: Hitnmiss::Entity.new('other value') }
    ]
  end
end
```

The `get(*args)` method is responsible for obtaining the value that you
want to cache by whatever means necessary and returning a
`Hitnmiss::Entity` containing the value. *Note:* The `*args` passed into
`get` method are whatever the args are that are passed into `prime` and
`fetch` methods when they are called.

If you wish to support the repository-level methods `all`, `clear`, and
`prime_all`, you *must* define the `get_all` method on the repository.
This method must return a collection of hashes describing the `args`
that would be used to fetch an entity and the corresponding
`Hitnmiss::Entity`. See example above.

### Set Cache Source based Expiration

In some cases you might need to set the expiration to be a different
value for each value. This is generally when you get back information in
the `get` method that you use to compute the expiration. Once you have
the expiration for that value you can set it by passing the expiration
into the `Hitnmiss::Entity` constructor as seen below.  *Note:* The
expiration in the `Hitnmiss::Entity` will take precedence over the
`default_expiration`.

```ruby
# lib/cache_repositories/most_recent_price.rb
class MostRecentPrice
  include Hitnmiss::Repository

  default_expiration 134

  def get(*args)
    # - do whatever to get the value you want to cache
    # - construct a Hitnmiss::Entity with the value and optionally a
    #   result based expiration. If no result based expiration is
    #   provided it will use the default_expiration.
    Hitnmiss::Entity.new('some value', 235)
  end
end
```

### Priming an entity

Once you have defined the `get` method. You can construct an instance of
your cache repository and use it. One way you might want to use it is to
force the repository to cache a value. This can be done using the
`prime` method as seen below.

```ruby
MostRecentPrice.new.prime(current_user.id) # => cached_value
```

### Priming the entire repository

You can use `prime_all` to prime the entire repository if the repository
implements `get_all`.

```ruby
MostRecentPrice.new.prime_all # => [cached values, ...]
```

### Fetching a value

You can also use your cache repository to fetch a particular cached
value by doing the following.

```ruby
MostRecentPrice.new.fetch(current_user.id) # => cached_value
```

### Deleting a cached value

You can delete a cached value by calling the `delete` with the arguments
used to fetch it.

```ruby
repository = MostRecentPrice.new
# cache some values ex: repository.prime(current_user.id)
repository.delete(current_user.id)
```

### Clearing a repository

You can clear the entire repository of cached values using `clear`.

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
