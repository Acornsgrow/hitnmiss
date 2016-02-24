require 'spec_helper'

describe Hitnmiss do
  it 'has a version number' do
    expect(Hitnmiss::VERSION).not_to be nil
  end

  describe "setting the cache driver" do
    it "specifies the cache driver to use" do
      Hitnmiss.register_driver(:my_driver, Hitnmiss::InMemoryDriver.new)
      cache_repo_klass = Class.new do
        include Hitnmiss::Repository

        driver :my_driver
      end
    end
  end

  describe "setting default expiration" do
    it "specifies the default expiration to use if the cacheable entity doesn't have an expiration" do
      cache_repo_klass = Class.new do
        include Hitnmiss::Repository

        default_expiration 134
      end
    end
  end

  describe "priming the cache" do
    it "obtains the value, caches it, and return the cached value" do
      cache_repo_klass = Class.new do
        include Hitnmiss::Repository

        def self.fetch_cacheable_entity(*args)
          Hitnmiss::Entity.new('foo', 235)
        end
      end

      expect(cache_repo_klass.prime_entity_cache('some_token')).to eq('foo')
    end
  end

  describe "setting cacheable entity expiration" do
    it "sets the expiration of the cache to cacheable entities expiration" do
      cache_repo_klass = Class.new do
        include Hitnmiss::Repository

        def self.fetch_cacheable_entity(*args)
          Hitnmiss::Entity.new('foo', 235)
        end
      end

      cur_time = Time.now.utc

      Timecop.freeze(cur_time) do
        cache_repo_klass.prime_entity_cache('some_token')

        driver = Hitnmiss.driver(:in_memory)
        cache = driver.instance_variable_get(:@cache)
        expect(cache['.String:some_token']['expiration']).to eq(cur_time.to_i + 235)
      end
    end
  end

  describe "fetching a not already cached value" do
    it "primes the cache, and returns the cached value" do
      cache_repo_klass = Class.new do
        include Hitnmiss::Repository

        def self.fetch_cacheable_entity(*args)
          Hitnmiss::Entity.new('foo', 235)
        end
      end

      expect(cache_repo_klass.fetch('some_token')).to eq('foo')
    end
  end

  describe "fetching an already cached value" do
    it "returns the cached value" do
      cache_repo_klass = Class.new do
        include Hitnmiss::Repository

        def self.fetch_cacheable_entity(*args)
          Hitnmiss::Entity.new('foo', 235)
        end
      end

      cache_repo_klass.prime_entity_cache

      expect(cache_repo_klass.fetch('some_token')).to eq('foo')
    end
  end
end
