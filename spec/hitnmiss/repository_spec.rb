require 'spec_helper'

describe Hitnmiss::Repository do
  describe '.driver' do
    context 'when given a driver identifier' do
      it 'sets driver to a registered driver' do
        repo_klass = Class.new do
          include Hitnmiss::Repository
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
            include Hitnmiss::Repository
            driver :some_driver
          end

          driver_name = repo_klass.driver
          expect(driver_name).to eq(:some_driver)
        end
      end

      context 'when driver has NOT been set' do
        it 'returns identifier for the default driver' do
          repo_klass = Class.new do
            include Hitnmiss::Repository
          end

          driver_name = repo_klass.driver
          expect(driver_name).to eq(:in_memory)
        end
      end
    end
  end

  describe '.default_expiration' do
    context 'when given an expiration' do
      it 'set the default expiration for the cache repository' do
        expiration = double('expiration')
        repo_klass = Class.new do
          include Hitnmiss::Repository

          default_expiration expiration
        end

        actual_default_expiration = repo_klass.instance_variable_get(:@default_expiration)
        expect(actual_default_expiration).to eq(expiration)
      end
    end

    context 'when NOT given an expiration' do
      context 'when default expiration has been set' do
        it 'returns the expiration' do
          expiration = double('expiration')
          repo_klass = Class.new do
            include Hitnmiss::Repository

            default_expiration expiration
          end

          actual_default_expiration = repo_klass.default_expiration
          expect(actual_default_expiration).to eq(expiration)
        end
      end
      
      context 'when default expiration has NOT been set' do
        it 'returns nil' do
          repo_klass = Class.new do
            include Hitnmiss::Repository
          end

          actual_default_expiration = repo_klass.default_expiration
          expect(actual_default_expiration).to eq(nil)
        end
      end
    end
  end

  describe '#fetch' do
    it 'raises error indicating not implemented' do
      repo_klass = Class.new do
        include Hitnmiss::Repository
      end

      expect { repo_klass.new.send(:fetch) }.to raise_error(Hitnmiss::Errors::NotImplemented)
    end
  end

  describe '#fetch_all' do
    it 'raises error indicating not implemented' do
      repo_klass = Class.new do
        include Hitnmiss::Repository
      end

      keyspace = double('keyspace')
      expect { repo_klass.new.send(:fetch_all, keyspace) }.to raise_error(Hitnmiss::Errors::NotImplemented)
    end
  end

  describe '#prime' do
    it 'obtains the cacheable entity' do
      repo_klass = Class.new do
        include Hitnmiss::Repository
        self.driver :my_driver
      end

      args = double('arguments')
      Hitnmiss.register_driver(:my_driver, double.as_null_object)
      repository = repo_klass.new
      expect(repository).to receive(:fetch).with(args).and_return(double.as_null_object)

      repository.prime(args)
    end

    context 'when cacheable entity has an expiration' do
      it 'caches the value with the expiration' do
        key = double('key')
        args = double('arguments')

        repo_klass = Class.new do
          include Hitnmiss::Repository
          self.driver :my_driver

          private

          def fetch(*args)
            Hitnmiss::Entity.new('myval', 22223)
          end
        end

        driver = double('cache driver')
        Hitnmiss.register_driver(:my_driver, driver)

        repository = repo_klass.new

        allow(repository).to receive(:generate_key).and_return(key)

        expect(driver).to receive(:set).with(key, 'myval', 22223)

        repository.prime(args)
      end
    end

    context 'when cacheable entity does not have an expiration' do
      it 'caches the value with the default expiration' do
        key = double('key')
        driver = double('cache driver')
        args = double('arguments')
        default_expiration = double('default expiration')

        repo_klass = Class.new do
          include Hitnmiss::Repository
          self.driver :my_driver

          private

          def fetch(*args)
            Hitnmiss::Entity.new('myval')
          end
        end
        Hitnmiss.register_driver(:my_driver, driver)

        repository = repo_klass.new

        allow(repository).to receive(:generate_key).and_return(key)

        repo_klass.instance_variable_set(:@default_expiration, default_expiration)

        expect(driver).to receive(:set).with(key, 'myval', default_expiration)

        repository.prime(args)
      end
    end

    it 'return the cacheable entity value' do
      repo_klass = Class.new do
        include Hitnmiss::Repository
      end

      entity = double(value: 'foovalue', expiration: 212).as_null_object
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

      repo_klass = Class.new do
        include Hitnmiss::Repository
        self.driver :my_driver

        private

        def fetch_all(keyspace)
          [
            { args: ['key1'], entity: Hitnmiss::Entity.new('myval', 22223) },
            { args: ['key2'], entity: Hitnmiss::Entity.new('myval2', 43564) }
          ]
        end
      end

      allow(repo_klass).to receive(:name).and_return('isotest_prime_all_1')

      driver = double('cache driver')
      Hitnmiss.register_driver(:my_driver, driver)

      repository = repo_klass.new

      allow(repository).to receive(:generate_key).with('key1').and_return(key1)
      allow(repository).to receive(:generate_key).with('key2').and_return(key2)

      expect(driver).to receive(:set).with(key1, 'myval', 22223)
      expect(driver).to receive(:set).with(key2, 'myval2', 43564)

      repository.prime_all
    end

    it 'returns the values of cached entities' do
      repo_klass = Class.new do
        include Hitnmiss::Repository
        self.driver :my_driver

        private

        def fetch_all(keyspace)
          [
            { args: ['key1'], entity: Hitnmiss::Entity.new('myval', 22223) },
            { args: ['key2'], entity: Hitnmiss::Entity.new('myval2', 43564) }
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
        include Hitnmiss::Repository
        self.driver :my_driver
      end

      hit = Hitnmiss::Driver::Hit.new('somevalue')
      driver = double('cache driver', get: hit)
      Hitnmiss.register_driver(:my_driver, driver)

      repository = repo_klass.new
      expect(repository).to receive(:generate_key).with('auaeuaoeua')
      repository.get('auaeuaoeua')
    end

    it 'attempts to obtained the cached value' do
      repo_klass = Class.new do
        include Hitnmiss::Repository
        driver :my_driver
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
          include Hitnmiss::Repository
          driver :my_driver
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
          include Hitnmiss::Repository
          driver :my_driver
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
          include Hitnmiss::Repository
          driver :my_driver
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
          include Hitnmiss::Repository
          driver :my_driver
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
        include Hitnmiss::Repository
        self.driver :my_driver
      end

      driver = double('cache driver', delete: nil)
      Hitnmiss.register_driver(:my_driver, driver)

      repository = repo_klass.new

      expect(repository).to receive(:generate_key).with('auaeuaoeua')

      repository.delete('auaeuaoeua')
    end

    it 'deletes the cached value' do
      repo_klass = Class.new do
        include Hitnmiss::Repository
        driver :my_driver
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
        include Hitnmiss::Repository
        self.driver :my_driver
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
        include Hitnmiss::Repository
        driver :my_driver
      end

      driver = double('cache driver')
      Hitnmiss.register_driver(:my_driver, driver)

      repository = repo_klass.new

      expect(driver).to receive(:clear)

      repository.clear
    end
  end
end
