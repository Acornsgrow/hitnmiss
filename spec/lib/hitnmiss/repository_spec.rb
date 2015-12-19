require 'spec_helper'

describe Hitnmiss::Repository do
  describe ".driver" do
    it "registers a driver instance" do
      some_driver = double('some driver')
      repo_klass = Class.new do
        include Hitnmiss::Repository
        driver some_driver
      end

      actual_driver = repo_klass.instance_variable_get(:@driver) 
      expect(actual_driver).to eq(some_driver)
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

  describe ".perform" do
    it "raises error indicating not implemented" do
      repo_klass = Class.new do
        include Hitnmiss::Repository
      end

      expect { repo_klass.perform }.to raise_error(Hitnmiss::Errors::NotImplemented)
    end
  end

  describe ".prime_cache" do
    it "obtains the cacheable entity" do
      repo_klass = Class.new do
        include Hitnmiss::Repository
      end

      args = double('arguments')
      repo_klass.instance_variable_set(:@driver, double.as_null_object)
      expect(repo_klass).to receive(:perform).with(args).and_return(double.as_null_object)
      
      repo_klass.prime_cache(args)
    end

    context "when cacheable entity has an expiration" do
      it "caches the value with the expiration" do
        key = double('key')
        driver = double('cache driver')
        args = double('arguments')

        repo_klass = Class.new do
          include Hitnmiss::Repository

          def self.perform(*args)
            Hitnmiss::Entity.new('myval', 22223)
          end
        end

        allow(repo_klass).to receive(:generate_key).and_return(key)

        repo_klass.instance_variable_set(:@driver, driver)
        expect(driver).to receive(:set).with(key, 'myval', 22223)
        
        repo_klass.prime_cache(args)
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

          def self.perform(*args)
            Hitnmiss::Entity.new('myval')
          end
        end

        allow(repo_klass).to receive(:generate_key).and_return(key)

        repo_klass.instance_variable_set(:@default_expiration, default_expiration)
        repo_klass.instance_variable_set(:@driver, driver)

        expect(driver).to receive(:set).with(key, 'myval', default_expiration)
        
        repo_klass.prime_cache(args)
      end
    end

    it "return the cacheable entity value" do
      repo_klass = Class.new do
        include Hitnmiss::Repository
        driver Hitnmiss::InMemoryDriver.new
      end

      entity = double(value: 'foovalue', expiration: 212).as_null_object

      args = double('arguments')
      allow(repo_klass).to receive(:perform).with(args).and_return(entity)
     
      expect(repo_klass.prime_cache(args)).to eq('foovalue')
    end
  end

  describe ".fetch" do
    it "attempts to obtained the cached value" do
      repo_klass = Class.new do
        include Hitnmiss::Repository
        driver Hitnmiss::InMemoryDriver.new
      end

      driver = double('cache driver')
      key = double('key')
      allow(repo_klass).to receive(:generate_key).and_return(key)
      repo_klass.instance_variable_set(:@driver, driver)
      allow(repo_klass).to receive(:prime_cache)

      expect(driver).to receive(:get).with(key)

      repo_klass.fetch('aoeuaoeuao')
    end

    context "when cached value was found" do
      it "returns the already cached value" do
        repo_klass = Class.new do
          include Hitnmiss::Repository
          driver Hitnmiss::InMemoryDriver.new
        end

        driver = double('cache driver')
        key = double('key')
        value = double('cached value')
        allow(repo_klass).to receive(:generate_key).and_return(key)
        repo_klass.instance_variable_set(:@driver, driver)

        expect(driver).to receive(:get).with(key).and_return(value)

        expect(repo_klass.fetch('aoeuaoeuao')).to eq(value)
      end
    end

    context "when cached value was NOT found" do
      it "primes the cache" do
        repo_klass = Class.new do
          include Hitnmiss::Repository
          driver Hitnmiss::InMemoryDriver.new
        end

        driver = double('cache driver')
        key = double('key')
        allow(repo_klass).to receive(:generate_key).and_return(key)
        repo_klass.instance_variable_set(:@driver, driver)
        allow(driver).to receive(:get).with(key).and_return(nil)
        expect(repo_klass).to receive(:prime_cache).with('aoeuaoeuao')

        repo_klass.fetch('aoeuaoeuao')
      end

      it "returns the newly cached value" do
        repo_klass = Class.new do
          include Hitnmiss::Repository
          driver Hitnmiss::InMemoryDriver.new
        end

        driver = double('cache driver')
        key = double('key')
        allow(repo_klass).to receive(:generate_key).and_return(key)
        repo_klass.instance_variable_set(:@driver, driver)
        allow(driver).to receive(:get).with(key).and_return(nil)
        allow(repo_klass).to receive(:prime_cache).and_return('porkpork')

        expect(repo_klass.fetch('aoeuaoeuao')).to eq('porkpork')
      end
    end
  end
end
