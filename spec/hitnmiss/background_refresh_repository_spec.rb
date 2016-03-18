require 'spec_helper'

RSpec.describe Hitnmiss::BackgroundRefreshRepository do
  describe '.driver' do
    context 'when given a driver identifier' do
      it 'sets driver to a registered driver' do
        repo_klass = Class.new do
          include Hitnmiss::BackgroundRefreshRepository
          driver :some_driver
        end

        driver_name = repo_klass.instance_variable_get(:@driver_name)
        expect(driver_name).to eq(:some_driver)
      end
    end

    context 'when NOT given a driver identifier' do
      context 'when driver has been set' do
        it 'returns the driver identifier' do
          repo_klass = Class.new do
            include Hitnmiss::BackgroundRefreshRepository
            driver :some_driver
          end

          driver_name = repo_klass.driver
          expect(driver_name).to eq(:some_driver)
        end
      end

      context 'when driver has NOT been set' do
        it 'returns identifier for the default driver' do
          repo_klass = Class.new do
            include Hitnmiss::BackgroundRefreshRepository
          end

          driver_name = repo_klass.driver
          expect(driver_name).to eq(:in_memory)
        end
      end
    end
  end

  describe '#fetch' do
    it 'raises error indicating not implemented' do
      repo_klass = Class.new do
        include Hitnmiss::BackgroundRefreshRepository
        refresh_interval 60
      end

      expect { repo_klass.new.send(:fetch) }.to raise_error(Hitnmiss::Errors::NotImplemented)
    end
  end

  describe '#fetch_all' do
    it 'raises error indicating not implemented' do
      repo_klass = Class.new do
        include Hitnmiss::BackgroundRefreshRepository
        refresh_interval 60
      end

      keyspace = double('keyspace')
      expect { repo_klass.new.send(:fetch_all, keyspace) }.to raise_error(Hitnmiss::Errors::NotImplemented)
    end
  end

  describe '.refresh_interval' do
    context 'when given a refresh interval' do
      it 'set the refresh interval for the cache repository' do
        interval = double('interval')
        repo_klass = Class.new do
          include Hitnmiss::BackgroundRefreshRepository
          refresh_interval interval
        end

        actual_interval = repo_klass.instance_variable_get(:@refresh_interval)
        expect(actual_interval).to eq(interval)
      end
    end

    context 'when NOT given a refresh interval' do
      context 'when refresh interval has previously been set' do
        it 'returns the refresh interval' do
          interval = double('interval')
          repo_klass = Class.new do
            include Hitnmiss::BackgroundRefreshRepository
            refresh_interval interval
          end

          actual_interval = repo_klass.refresh_interval
          expect(actual_interval).to eq(interval)
        end
      end

      context 'when refresh interval has NOT been set' do
        it 'returns nil' do
          repo_klass = Class.new do
            include Hitnmiss::BackgroundRefreshRepository
          end

          actual_interval = repo_klass.refresh_interval
          expect(actual_interval).to eq(nil)
        end
      end
    end
  end

  describe '#prime' do
    it 'obtains the cacheable entity' do
      repo_klass = Class.new do
        include Hitnmiss::BackgroundRefreshRepository
        self.driver :my_driver
        refresh_interval 60
      end

      args = double('arguments')
      Hitnmiss.register_driver(:my_driver, double.as_null_object)
      repository = repo_klass.new
      expect(repository).to receive(:fetch).with(args).and_return(double.as_null_object)

      repository.prime(args)
    end

    context 'when cacheable entity has an expiration' do
      it 'caches the value without the expiration' do
        key = double('key')
        args = double('arguments')

        entity = Hitnmiss::Entity.new('myval')

        repo_klass = Class.new do
          include Hitnmiss::BackgroundRefreshRepository
          self.driver :my_driver
          refresh_interval 60

          private

          def fetch(*args)
            Hitnmiss::Entity.new('myval')
          end
        end

        allow(Hitnmiss::Entity).to receive(:new).with('myval').and_return(entity)

        driver = double('cache driver')
        Hitnmiss.register_driver(:my_driver, driver)

        repository = repo_klass.new

        allow(repository).to receive(:generate_key).and_return(key)

        expect(driver).to receive(:set).with(key, entity)

        repository.prime(args)
      end
    end

    context 'when cacheable entity does not have an expiration' do
      it 'caches the value without an expiration' do
        key = double('key')
        driver = double('cache driver')
        args = double('arguments')
        entity = Hitnmiss::Entity.new('myval')

        repo_klass = Class.new do
          include Hitnmiss::BackgroundRefreshRepository
          self.driver :my_driver
          refresh_interval 60

          private

          def fetch(*args)
            Hitnmiss::Entity.new('myval')
          end
        end
        Hitnmiss.register_driver(:my_driver, driver)

        allow(Hitnmiss::Entity).to receive(:new).with('myval').and_return(entity)

        repository = repo_klass.new

        allow(repository).to receive(:generate_key).and_return(key)

        expect(driver).to receive(:set).with(key, entity)

        repository.prime(args)
      end
    end

    it 'return the cacheable entity value' do
      repo_klass = Class.new do
        include Hitnmiss::BackgroundRefreshRepository
        refresh_interval 60
      end

      entity = double(value: 'foovalue').as_null_object
      args = double('arguments')

      repository = repo_klass.new

      allow(repository).to receive(:fetch).with(args).and_return(entity)

      expect(repository.prime(args)).to eq('foovalue')
    end
  end

  describe '#prime_all' do
    it 'caches cacheable entities' do
      key1 = double('key 1')
      key2 = double('key 2')
      entity1 = Hitnmiss::Entity.new('myval')
      entity2 = Hitnmiss::Entity.new('myval2')

      repo_klass = Class.new do
        include Hitnmiss::BackgroundRefreshRepository
        self.driver :my_driver
        refresh_interval 60

        private

        def fetch_all(keyspace)
          [
            { args: ['key1'], entity: Hitnmiss::Entity.new('myval') },
            { args: ['key2'], entity: Hitnmiss::Entity.new('myval2') }
          ]
        end
      end

      allow(repo_klass).to receive(:name).and_return('isotest_prime_all_1')
      allow(Hitnmiss::Entity).to receive(:new).with('myval').and_return(entity1)
      allow(Hitnmiss::Entity).to receive(:new).with('myval2').and_return(entity2)

      driver = double('cache driver')
      Hitnmiss.register_driver(:my_driver, driver)

      repository = repo_klass.new

      allow(repository).to receive(:generate_key).with('key1').and_return(key1)
      allow(repository).to receive(:generate_key).with('key2').and_return(key2)

      expect(driver).to receive(:set).with(key1, entity1)
      expect(driver).to receive(:set).with(key2, entity2)

      repository.prime_all
    end

    it 'returns the values of cached entities' do
      repo_klass = Class.new do
        include Hitnmiss::BackgroundRefreshRepository
        self.driver :my_driver
        refresh_interval 60

        private

        def fetch_all(keyspace)
          [
            { args: ['key1'], entity: Hitnmiss::Entity.new('myval') },
            { args: ['key2'], entity: Hitnmiss::Entity.new('myval2') }
          ]
        end
      end

      allow(repo_klass).to receive(:name).and_return('isotest_prime_all_2')

      driver = double('cache driver')
      Hitnmiss.register_driver(:my_driver, driver)

      repository = repo_klass.new

      allow(repository).to receive(:generate_key)
      allow(driver).to receive(:set)

      expect(repository.prime_all).to match_array(['myval', 'myval2'])
    end
  end

  describe '#get' do
    it 'generates the cache key' do
      repo_klass = Class.new do
        include Hitnmiss::BackgroundRefreshRepository
        self.driver :my_driver
        refresh_interval 60
      end

      hit = Hitnmiss::Driver::Hit.new('somevalue')
      driver = double('cache driver', get: hit)
      Hitnmiss.register_driver(:my_driver, driver)

      repository = repo_klass.new
      expect(repository).to receive(:generate_key).with('auaeuaoeua')
      repository.get('auaeuaoeua')
    end

    it 'attempts to obtain the cached value' do
      repo_klass = Class.new do
        include Hitnmiss::BackgroundRefreshRepository
        driver :my_driver
        refresh_interval 60
      end

      hit = Hitnmiss::Driver::Hit.new('somevalue')
      driver = double('cache driver')
      Hitnmiss.register_driver(:my_driver, driver)

      repository = repo_klass.new
      key = double('key')
      allow(repository).to receive(:generate_key).and_return(key)
      allow(repository).to receive(:prime)

      expect(driver).to receive(:get).with(key).and_return(hit)

      repository.get('aoeuaoeuao')
    end

    context 'when driver responds with a hit' do
      it 'returns the already cached value' do
        repo_klass = Class.new do
          include Hitnmiss::BackgroundRefreshRepository
          driver :my_driver
          refresh_interval 60
        end

        hit = Hitnmiss::Driver::Hit.new('somevalue')
        driver = double('cache driver')
        Hitnmiss.register_driver(:my_driver, driver)

        repository = repo_klass.new
        key = double('key')
        allow(repository).to receive(:generate_key).and_return(key)

        expect(driver).to receive(:get).with(key).and_return(hit)
        expect(repository.get('aoeuaoeuao')).to eq('somevalue')
      end
    end

    context 'when driver responds with a miss' do
      it 'primes the cache' do
        repo_klass = Class.new do
          include Hitnmiss::BackgroundRefreshRepository
          driver :my_driver
          refresh_interval 60
        end

        miss = Hitnmiss::Driver::Miss.new
        driver = double('cache driver')
        Hitnmiss.register_driver(:my_driver, driver)

        repository = repo_klass.new
        key = double('key')
        allow(repository).to receive(:generate_key).and_return(key)
        allow(driver).to receive(:get).with(key).and_return(miss)
        expect(repository).to receive(:prime).with('aoeuaoeuao')

        repository.get('aoeuaoeuao')
      end

      it 'returns the newly cached value' do
        repo_klass = Class.new do
          include Hitnmiss::BackgroundRefreshRepository
          driver :my_driver
          refresh_interval 60
        end

        miss = Hitnmiss::Driver::Miss.new
        driver = double('cache driver')
        Hitnmiss.register_driver(:my_driver, driver)

        repository = repo_klass.new
        key = double('key')
        allow(repository).to receive(:generate_key).and_return(key)
        allow(driver).to receive(:get).with(key).and_return(miss)
        allow(repository).to receive(:prime).and_return('porkpork')

        expect(repository.get('aoeuaoeuao')).to eq('porkpork')
      end
    end

    context 'when driver responds with neither a hit or miss' do
      it 'raises an unsupported driver response exception' do
        repo_klass = Class.new do
          include Hitnmiss::BackgroundRefreshRepository
          driver :my_driver
          refresh_interval 60
        end

        driver = double('cache driver')
        Hitnmiss.register_driver(:my_driver, driver)

        repository = repo_klass.new
        key = double('key')
        allow(repository).to receive(:generate_key).and_return(key)
        allow(driver).to receive(:get).with(key).and_return(nil)

        expect { repository.get('aoeuaoeuao') }.to raise_error(Hitnmiss::Repository::UnsupportedDriverResponse,
          "Driver ':my_driver' did not return an object of the support types (Hitnmiss::Driver::Hit, Hitnmiss::Driver::Miss)")
      end
    end
  end

  describe '#delete' do
    it 'generates the cache key' do
      repo_klass = Class.new do
        include Hitnmiss::BackgroundRefreshRepository
        self.driver :my_driver
        refresh_interval 60
      end

      driver = double('cache driver', delete: nil)
      Hitnmiss.register_driver(:my_driver, driver)

      repository = repo_klass.new

      expect(repository).to receive(:generate_key).with('auaeuaoeua')

      repository.delete('auaeuaoeua')
    end

    it 'deletes the cached value' do
      repo_klass = Class.new do
        include Hitnmiss::BackgroundRefreshRepository
        driver :my_driver
        refresh_interval 60
      end

      driver = double('cache driver')
      Hitnmiss.register_driver(:my_driver, driver)

      repository = repo_klass.new

      key = double('key')
      allow(repository).to receive(:generate_key).and_return(key)

      expect(driver).to receive(:delete).with(key)

      repository.delete('aoeuaoeuao')
    end
  end

  describe '#all' do
    it 'returns all values for the keyspace' do
      repo_klass = Class.new do
        include Hitnmiss::BackgroundRefreshRepository
        self.driver :my_driver
        refresh_interval 60
      end

      entities = double('collection of cached values')

      driver = double('cache driver', all: entities)
      Hitnmiss.register_driver(:my_driver, driver)

      repository = repo_klass.new

      expect(repository.all).to eq entities
    end
  end

  describe '#clear' do
    it 'clears all the values' do
      repo_klass = Class.new do
        include Hitnmiss::BackgroundRefreshRepository
        driver :my_driver
        refresh_interval 60
      end

      driver = double('cache driver')
      Hitnmiss.register_driver(:my_driver, driver)

      repository = repo_klass.new

      expect(driver).to receive(:clear)

      repository.clear
    end
  end

  describe '#new' do
    context 'when refresh interval previously set' do
      it 'constructs an instance of the repository' do
        repo_klass = Class.new do
          include Hitnmiss::BackgroundRefreshRepository
          refresh_interval 60
        end

        repository = repo_klass.new
        expect(repository).to be_a(repo_klass)
      end
    end

    context 'when refresh interval NOT previously set' do
      it 'raises an exception notifying that it is required' do
        repo_klass = Class.new do
          include Hitnmiss::BackgroundRefreshRepository
        end

        expect { repo_klass.new }.to \
        raise_error(Hitnmiss::BackgroundRefreshRepository::RefreshIntervalRequired)
      end
    end
  end

  describe '#stale?' do
    it 'returns true' do
      repo_klass = Class.new do
        include Hitnmiss::BackgroundRefreshRepository
        refresh_interval 60
      end

      repository = repo_klass.new

      expect(repository.stale?('foo')).to eq(true)
    end
  end

  describe '#refresh' do
    it 'checks if the cache is stale' do
      repo_klass = Class.new do
        include Hitnmiss::BackgroundRefreshRepository
        refresh_interval 60
      end

      repository = repo_klass.new

      args = double('args')
      expect(repository).to receive(:stale?).with(args)
      repository.refresh(args)
    end

    context 'when cache is stale' do
      it 'primes the cache' do
        repo_klass = Class.new do
          include Hitnmiss::BackgroundRefreshRepository
          refresh_interval 60
        end

        repository = repo_klass.new
        allow(repository).to receive(:stale?).and_return(true)

        args = double('args')
        expect(repository).to receive(:prime).with(args)
        repository.refresh(args)
      end
    end

    context 'when cache is NOT stale' do
      it 'does NOT prime the cache' do
        repo_klass = Class.new do
          include Hitnmiss::BackgroundRefreshRepository
          refresh_interval 60
        end

        repository = repo_klass.new
        allow(repository).to receive(:stale?).and_return(false)

        args = double('args')
        expect(repository).not_to receive(:prime)
        repository.refresh(args)
      end
    end
  end
end
