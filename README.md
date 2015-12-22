[![Build Status](https://travis-ci.com/Acornsgrow/hitnmiss.svg?token=GGEgqzL4zt7sa3zVgspU&branch=master)](https://travis-ci.com/Acornsgrow/hitnmiss)
[![Code Climate](https://codeclimate.com/repos/567a3c30bd3f3b63510017dd/badges/e979a32e79ec12d35896/gpa.svg)](https://codeclimate.com/repos/567a3c30bd3f3b63510017dd/feed)
[![Test Coverage](https://codeclimate.com/repos/567a3c30bd3f3b63510017dd/badges/e979a32e79ec12d35896/coverage.svg)](https://codeclimate.com/repos/567a3c30bd3f3b63510017dd/coverage)
[![Issue Count](https://codeclimate.com/repos/567a3c30bd3f3b63510017dd/badges/e979a32e79ec12d35896/issue_count.svg)](https://codeclimate.com/repos/567a3c30bd3f3b63510017dd/feed)

# Hitnmiss

Hitnmiss is a Ruby gem that provides support for using the Repository
pattern for read-through, write-behind caching. It is built heavily
around using POROs (Plain Old Ruby Objects). This means it is intended
to be used with all kinds of Ruby applications from plain Ruby command
line tools, to framework (Rails, Sinatra, Rack, Lotus, etc.) based web
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
persistance layer and the business representation.

###  Set a Repositories Cache Driver

Once you have a defined a `class` and mixed in the
`Hitnmiss::Repository` module. You need to tell `Hitnmiss` what driver
to use for this particular repository. The following is an example of
how one would accomplish setting the driver to the provided
`Hitnmiss::InMemoryDriver`.

```ruby
# lib/cache_repositories/most_recent_price.rb
class MostRecentPrice
  include Hitnmiss::Repository

  driver Hitnmiss::InMemoryDriver.new
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

  driver Hitnmiss::InMemoryDriver.new
  default_expiration 134
end
```

### Define Cache Source

You may be asking yourself, "How does the cache value get set?" Well,
the answer is by defining the the `self.perform(*args)` method. This
method is responsible for obtaining the value that you want to cache by
whatever means necessary and returning a `Hitnmiss::Entity` containing
the value. *Note:* The `*args` passed into `self.perform` are whatever
the args are that are passed into `prime_cache` and `fetch` when those
methods are called.

```ruby
# lib/cache_repositories/most_recent_price.rb
class MostRecentPrice
  include Hitnmiss::Repository

  driver Hitnmiss::InMemoryDriver.new
  default_expiration 134

  def self.perform(*args)
    # - do whatever to get the value you want to cache
    # - construct a Hitnmiss::Entity with the value
    Hitnmiss::Entity.new('some value')
  end
end
```

### Set Cache Source based Expiration

In some cases you might need to set the expiration to be a different
value for each value. This is generally when you get back information in
the `self.perform` method that you use to compute the expiration. Once
you have the expiration for that value you can set it by passing the
expiration into the `Hitnmiss::Entity` constructor as seen below.
*Note:* The expiration in the `Hitnmiss::Entity` will take precedence
over the `default_expiration`.

```ruby
# lib/cache_repositories/most_recent_price.rb
class MostRecentPrice
  include Hitnmiss::Repository

  driver Hitnmiss::InMemoryDriver.new
  default_expiration 134

  def self.perform(*args)
    # - do whatever to get the value you want to cache
    # - construct a Hitnmiss::Entity with the value and optionally a
    #   result based expiration. If no result based expiration is
    #   provided it will use the default_expiration.
    Hitnmiss::Entity.new('some value', 235)
  end
end
```

### Priming Cache

Once you have defined the `self.perform` method. You can actually use
your cache repository. One way you might want to use it is to force the
repository to fetch the value using `self.perform` and cache the
resulting value. This can be done using the `prime_cache` method as seen
below.

```ruby
MostRecentPrice.prime_cache(current_user.id)
```

### Fetching a Value

You can also use your cache repository to of course fetch a particular
cached value by doing something like the following.

```ruby
MostRecentPrice.fetch(current_user.id)
```

## ToDo

- Write a separate hitnmiss-redis_driver gem to implement the hitnmiss
  driver interface for Redis. Note: The README.md for both projects
  should reference one another.

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
https://github.com/[USERNAME]/hitnmiss. This project is intended to be a
safe, welcoming space for collaboration, and contributors are expected
to adhere to the [Contributor Covenant](http://contributor-covenant.org)
code of conduct.

## License

The gem is available as open source under the terms of the [MIT
License](http://opensource.org/licenses/MIT).

