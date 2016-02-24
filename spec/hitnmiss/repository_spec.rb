require 'spec_helper'

describe Hitnmiss::Repository do
  describe ".driver" do
    it "registers a driver name" do
      repo_klass = Class.new do
        include Hitnmiss::Repository
        driver :some_driver
      end

      driver_name = repo_klass.instance_variable_get(:@driver_name)
      expect(driver_name).to eq(:some_driver)
    end
  end

  describe ".default_expiration" do
    it "set the default expiration for the cache repository" do
      expiration = double('expiration')
      repo_klass = Class.new do
        include Hitnmiss::Repository

        default_expiration expiration
      end

      actual_default_expiration = repo_klass.instance_variable_get(:@default_expiration)
      expect(actual_default_expiration).to eq(expiration)
    end
  end

  describe ".generate_key" do
    it "generates a key from the class and the given arguments" do
      repo_klass = Class.new do
        include Hitnmiss::Repository
      end

      allow(repo_klass).to receive(:name).and_return('HooptyJack')

      expect(repo_klass.generate_key('true', true, 1, 'zar')).to \
        eq("HooptyJack.String:true.TrueClass:true.Fixnum:1.String:zar")
    end
  end

  describe ".get" do
    it "raises error indicating not implemented" do
      repo_klass = Class.new do
        include Hitnmiss::Repository
      end

      expect { repo_klass.get }.to raise_error(Hitnmiss::Errors::NotImplemented)
    end
  end

  describe ".get_all" do
    it "raises error indicating not implemented" do
      repo_klass = Class.new do
        include Hitnmiss::Repository
      end

      keyspace = double('keyspace')
      expect { repo_klass.get_all(keyspace) }.to raise_error(Hitnmiss::Errors::NotImplemented)
    end
  end

  describe ".prime" do
    it "obtains the cacheable entity" do
      repo_klass = Class.new do
        include Hitnmiss::Repository
        self.driver :my_driver
      end

      args = double('arguments')
      Hitnmiss.register_driver(:my_driver, double.as_null_object)
      expect(repo_klass).to receive(:get).with(args).and_return(double.as_null_object)

      repo_klass.prime(args)
    end

    context "when cacheable entity has an expiration" do
      it "caches the value with the expiration" do
        key = double('key')
        driver = double('cache driver')
        args = double('arguments')

        repo_klass = Class.new do
          include Hitnmiss::Repository
          self.driver :my_driver

          def self.get(*args)
            Hitnmiss::Entity.new('myval', 22223)
          end
        end
        Hitnmiss.register_driver(:my_driver, driver)

        allow(repo_klass).to receive(:generate_key).and_return(key)

        expect(driver).to receive(:set).with(key, 'myval', 22223)

        repo_klass.prime(args)
      end
    end

    context "when cacheable entity does not have an expiration" do
      it "caches the value with the default expiration" do
        key = double('key')
        driver = double('cache driver')
        args = double('arguments')
        default_expiration = double('default expiration')

        repo_klass = Class.new do
          include Hitnmiss::Repository
          self.driver :my_driver

          def self.get(*args)
            Hitnmiss::Entity.new('myval')
          end
        end
        Hitnmiss.register_driver(:my_driver, driver)

        allow(repo_klass).to receive(:generate_key).and_return(key)

        repo_klass.instance_variable_set(:@default_expiration, default_expiration)

        expect(driver).to receive(:set).with(key, 'myval', default_expiration)

        repo_klass.prime(args)
      end
    end

    it "return the cacheable entity value" do
      repo_klass = Class.new do
        include Hitnmiss::Repository
      end

      entity = double(value: 'foovalue', expiration: 212).as_null_object

      args = double('arguments')
      allow(repo_klass).to receive(:get).with(args).and_return(entity)

      expect(repo_klass.prime(args)).to eq('foovalue')
    end
  end

  describe ".prime_all" do
    it 'caches cacheable entities' do
      key1 = double('key 1')
      key2 = double('key 2')
      driver = double('cache driver')

      repo_klass = Class.new do
        include Hitnmiss::Repository
        self.driver :my_driver

        def self.get_all(keyspace)
          [
            { args: ['key1'], entity: Hitnmiss::Entity.new('myval', 22223) },
            { args: ['key2'], entity: Hitnmiss::Entity.new('myval2', 43564) }
          ]
        end
      end
      Hitnmiss.register_driver(:my_driver, driver)

      allow(repo_klass).to receive(:generate_key).with('key1').and_return(key1)
      allow(repo_klass).to receive(:generate_key).with('key2').and_return(key2)

      expect(driver).to receive(:set).with(key1, 'myval', 22223)
      expect(driver).to receive(:set).with(key2, 'myval2', 43564)

      repo_klass.prime_all
    end

    it 'returns the values of cached entities' do
      driver = double('cache driver')

      repo_klass = Class.new do
        include Hitnmiss::Repository
        self.driver :my_driver

        def self.get_all(keyspace)
          [
            { args: ['key1'], entity: Hitnmiss::Entity.new('myval', 22223) },
            { args: ['key2'], entity: Hitnmiss::Entity.new('myval2', 43564) }
          ]
        end
      end
      Hitnmiss.register_driver(:my_driver, driver)

      allow(repo_klass).to receive(:generate_key)
      allow(driver).to receive(:set)

      expect(repo_klass.prime_all).to match_array(['myval', 'myval2'])
    end
  end

  describe ".fetch" do
    it "generates the cache key" do
      repo_klass = Class.new do
        include Hitnmiss::Repository
        self.driver :my_driver
      end

      driver = double('cache driver', get: double('value'))
      expect(repo_klass).to receive(:generate_key).with('auaeuaoeua')
      Hitnmiss.register_driver(:my_driver, driver)

      repo_klass.fetch('auaeuaoeua')
    end

    it "attempts to obtained the cached value" do
      repo_klass = Class.new do
        include Hitnmiss::Repository
        driver :my_driver
      end

      driver = double('cache driver')
      Hitnmiss.register_driver(:my_driver, driver)
      key = double('key')
      allow(repo_klass).to receive(:generate_key).and_return(key)
      allow(repo_klass).to receive(:prime)

      expect(driver).to receive(:get).with(key)

      repo_klass.fetch('aoeuaoeuao')
    end

    context "when cached value was found" do
      context "when the cached value is the boolean false" do
        it "returns the already cached value" do
          repo_klass = Class.new do
            include Hitnmiss::Repository
            driver :my_driver
          end

          driver = double('cache driver')
          key = double('key')
          value = false
          allow(repo_klass).to receive(:generate_key).and_return(key)
          Hitnmiss.register_driver(:my_driver, driver)

          expect(driver).to receive(:get).with(key).and_return(value)

          expect(repo_klass.fetch('aoeuaoeuao')).to eq(value)
        end
      end

      context "when the cached value is not the boolean false" do
        it "returns the already cached value" do
          repo_klass = Class.new do
            include Hitnmiss::Repository
            driver :my_driver
          end

          driver = double('cache driver')
          key = double('key')
          value = double('cached value')
          allow(repo_klass).to receive(:generate_key).and_return(key)
          Hitnmiss.register_driver(:my_driver, driver)

          expect(driver).to receive(:get).with(key).and_return(value)

          expect(repo_klass.fetch('aoeuaoeuao')).to eq(value)
        end
      end
    end

    context "when cached value was NOT found" do
      it "primes the cache" do
        repo_klass = Class.new do
          include Hitnmiss::Repository
          driver :my_driver
        end

        driver = double('cache driver')
        key = double('key')
        allow(repo_klass).to receive(:generate_key).and_return(key)
        Hitnmiss.register_driver(:my_driver, driver)
        allow(driver).to receive(:get).with(key).and_return(nil)
        expect(repo_klass).to receive(:prime).with('aoeuaoeuao')

        repo_klass.fetch('aoeuaoeuao')
      end

      it "returns the newly cached value" do
        repo_klass = Class.new do
          include Hitnmiss::Repository
          driver :my_driver
        end

        driver = double('cache driver')
        key = double('key')
        allow(repo_klass).to receive(:generate_key).and_return(key)
        Hitnmiss.register_driver(:my_driver, driver)
        allow(driver).to receive(:get).with(key).and_return(nil)
        allow(repo_klass).to receive(:prime).and_return('porkpork')

        expect(repo_klass.fetch('aoeuaoeuao')).to eq('porkpork')
      end
    end
  end

  describe '.delete' do
    it 'generates the cache key' do
      repo_klass = Class.new do
        include Hitnmiss::Repository
        self.driver :my_driver
      end

      driver = double('cache driver', delete: nil)
      expect(repo_klass).to receive(:generate_key).with('auaeuaoeua')
      Hitnmiss.register_driver(:my_driver, driver)

      repo_klass.delete('auaeuaoeua')
    end

    it 'deletes the cached value' do
      repo_klass = Class.new do
        include Hitnmiss::Repository
        driver :my_driver
      end

      driver = double('cache driver')
      Hitnmiss.register_driver(:my_driver, driver)
      key = double('key')
      allow(repo_klass).to receive(:generate_key).and_return(key)

      expect(driver).to receive(:delete).with(key)

      repo_klass.delete('aoeuaoeuao')
    end
  end

  describe '.all' do
    it 'returns all values for the keyspace' do
      repo_klass = Class.new do
        include Hitnmiss::Repository
        self.driver :my_driver
      end

      entities = double('collection of entities')

      driver = double('cache driver', all: entities)
      Hitnmiss.register_driver(:my_driver, driver)

      expect(repo_klass.all).to eq entities
    end
  end

  describe '.clear' do
    it 'clears all the values' do
      repo_klass = Class.new do
        include Hitnmiss::Repository
        driver :my_driver
      end

      driver = double('cache driver')
      Hitnmiss.register_driver(:my_driver, driver)

      expect(driver).to receive(:clear)

      repo_klass.clear
    end
  end
end
