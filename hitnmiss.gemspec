# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'hitnmiss/version'

Gem::Specification.new do |spec|
  spec.name          = "hitnmiss"
  spec.version       = Hitnmiss::VERSION
  spec.authors       = ["Andrew De Ponte", "Brian Miller", "Kyle Chong"]
  spec.email         = ["cyphactor@gmail.com", "brimil01@gmail.com", "me@kylechong.com"]

  spec.summary       = %q{Ruby read-through, write-behind caching using POROs}
  spec.description   = %q{Ruby gem to support using the Repository pattern for read-through, write-behind caching using POROs}
  spec.homepage      = "https://github.com/Acornsgrow/hitnmiss"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.11"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "timecop", "~> 0.8"
  spec.add_development_dependency "simplecov", "~> 0.11"
  spec.add_development_dependency "codeclimate-test-reporter", "~> 0.4"
end
