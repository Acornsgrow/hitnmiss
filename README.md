[![Code Climate](https://codeclimate.com/repos/567a3c30bd3f3b63510017dd/badges/e979a32e79ec12d35896/gpa.svg)](https://codeclimate.com/repos/567a3c30bd3f3b63510017dd/feed)
[![Test Coverage](https://codeclimate.com/repos/567a3c30bd3f3b63510017dd/badges/e979a32e79ec12d35896/coverage.svg)](https://codeclimate.com/repos/567a3c30bd3f3b63510017dd/coverage)
[![Issue Count](https://codeclimate.com/repos/567a3c30bd3f3b63510017dd/badges/e979a32e79ec12d35896/issue_count.svg)](https://codeclimate.com/repos/567a3c30bd3f3b63510017dd/feed)

# Hitnmiss

Welcome to your new gem! In this directory, you'll find the files you need to be able to package up your Ruby library into a gem. Put your Ruby code in the file `lib/hitnmiss`. To experiment with that code, run `bin/console` for an interactive prompt.

TODO: Delete this and the text above, and describe your gem

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

TODO: Write usage instructions here

## ToDo

- Add a test to the ".fetch" that makes sure it first calls
  `generate_key` and then "attempts to obtain the cached value".
- Write a useful README.md that will help people understand how to use
  this library.
- Write a separate hitnmiss-redis_driver gem to implement the hitnmiss
  driver interface for Redis. Note: The README.md for both projects
  should reference one another.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/hitnmiss. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

