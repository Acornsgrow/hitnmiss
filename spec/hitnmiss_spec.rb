require 'spec_helper'

describe Hitnmiss do
  it 'has a version number' do
    expect(Hitnmiss::VERSION).not_to be nil
  end

  describe "setting the cache driver" do
    it "specifies the cache driver to use" do
      Hitnmiss.register_driver(:my_driver, Hitnmiss::InMemoryDriver.new)
      repo_klass = Class.new do
        include Hitnmiss::Repository

        driver :my_driver
      end
    end
  end

  describe "setting default expiration" do
    it "specifies the default expiration to use if the cacheable entity doesn't have an expiration" do
      repo_klass = Class.new do
        include Hitnmiss::Repository

        default_expiration 134
      end
    end
  end

  describe "priming the cache" do
    it "obtains the value, caches it, and return the cached value" do
      repo_klass = Class.new do
        include Hitnmiss::Repository

        def get(*args)
          Hitnmiss::Entity.new('foo', 235)
        end
      end

      allow(repo_klass).to receive(:name).and_return('test_prime')

      expect(repo_klass.new.prime('some_token')).to eq('foo')
    end
  end

  describe "setting cacheable entity expiration" do
    it "sets the expiration of the cache to cacheable entities expiration" do
      repo_klass = Class.new do
        include Hitnmiss::Repository

        def get(*args)
          Hitnmiss::Entity.new('foo', 235)
        end
      end

      allow(repo_klass).to receive(:name).and_return('test_entity_expir')

      cur_time = Time.now.utc

      Timecop.freeze(cur_time) do
        repo_klass.new.prime('some_token')

        driver = Hitnmiss.driver(:in_memory)
        cache = driver.instance_variable_get(:@cache)
        expect(cache['test_entity_expir.String:some_token']['expiration']).to eq(cur_time.to_i + 235)
      end
    end
  end

  describe "fetching a not already cached value" do
    it "primes the cache, and returns the cached value" do
      repo_klass = Class.new do
        include Hitnmiss::Repository

        def get(*args)
          Hitnmiss::Entity.new('foo', 235)
        end
      end

      allow(repo_klass).to receive(:name).and_return('test_fetch_noncached')

      expect(repo_klass.new.fetch('some_token')).to eq('foo')
    end
  end

  describe "fetching an already cached value" do
    it "returns the cached value" do
      repo_klass = Class.new do
        include Hitnmiss::Repository

        def get(*args)
          Hitnmiss::Entity.new('foo', 235)
        end
      end

      allow(repo_klass).to receive(:name).and_return('test_fetch_cached')

      repository = repo_klass.new
      repository.prime

      expect(repository.fetch('some_token')).to eq('foo')
    end
  end

  describe 'prime entire repository with cached values' do
    it 'returns the cached values' do
      repo_klass = Class.new do
        include Hitnmiss::Repository

        def get_all(keyspace)
          [
            { args: ['key1'], entity: Hitnmiss::Entity.new('myval', 22223) },
            { args: ['key2'], entity: Hitnmiss::Entity.new('myval2', 43564) }
          ]
        end
      end

      allow(repo_klass).to receive(:name).and_return('test_prime_all')

      repository = repo_klass.new

      expect(repository.prime_all).to eq(['myval', 'myval2'])
    end
  end

  describe 'fetch all cached values' do
    it 'returns all the currently cached values' do
      repo_klass = Class.new do
        include Hitnmiss::Repository

        def get(*args)
          if args.first && args.first == 'hi'
            Hitnmiss::Entity.new('hello', 235)
          else
            Hitnmiss::Entity.new('goodbye', 235)
          end
        end
      end

      allow(repo_klass).to receive(:name).and_return('test_all')

      repository = repo_klass.new
      repository.prime('hi')
      repository.prime('something_else')

      expect(repository.all).to eq(['hello', 'goodbye'])
    end
  end

  describe 'delete a cached value' do
    it 'deletes the cached value' do
      repo_klass = Class.new do
        include Hitnmiss::Repository

        def get(*args)
          Hitnmiss::Entity.new('foo', 235)
        end
      end

      allow(repo_klass).to receive(:name).and_return('test_delete')

      repository = repo_klass.new

      repository.prime('aoeuaoeuao')
      repository.delete('aoeuaoeuao')
      expect(repository.all).to be_empty
    end
  end

  describe 'clear all cached values' do
    it 'deletes all the cached values' do
      repo_klass = Class.new do
        include Hitnmiss::Repository

        def get(*args)
          if args.first && args.first == 'hi'
            Hitnmiss::Entity.new('hello', 235)
          else
            Hitnmiss::Entity.new('goodbye', 235)
          end
        end
      end

      allow(repo_klass).to receive(:name).and_return('test_delete')

      repository = repo_klass.new
      repository.prime('hi')
      repository.prime('something_else')
      repository.clear

      expect(repository.all).to be_empty
    end
  end
end
