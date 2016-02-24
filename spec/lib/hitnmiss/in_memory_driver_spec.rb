require 'spec_helper'

describe "Hitnmiss::InMemoryDriver" do
  describe ".new" do
    it "constructs an Hitnmiss::InMemoryDriver" do
      driver = Hitnmiss::InMemoryDriver.new
      expect(driver).to be_a(Hitnmiss::InMemoryDriver)
    end

    it "initializes the internal cache store to an empty hash" do
      driver = Hitnmiss::InMemoryDriver.new
      cache_hash = driver.instance_variable_get(:@cache)
      expect(cache_hash).to eq({})
    end
  end

  describe "#set" do
    it "caches the given value, using the given key and expiration" do
      driver = Hitnmiss::InMemoryDriver.new
      now = Time.now.utc
      Timecop.freeze(now) do
        driver.set('some_key', 'some_value', 1)
      end
      cache = driver.instance_variable_get(:@cache)
      expect(cache['some_key']['value']).to eq('some_value')
      expect(cache['some_key']['expiration']).to eq(now.to_i + 1)
    end
  end

  describe "#get" do
    context "when key matches something cached" do
      context "when we have passed the expiration" do
        it "returns nil indicating a miss" do
          driver = Hitnmiss::InMemoryDriver.new
          cur_time = Time.now.utc
          Timecop.freeze(cur_time) do
            cache = { 'some_key' => { 'value' => 'foo', 'expiration' => (cur_time.to_i - 423423) } }
            driver.instance_variable_set(:@cache, cache)
            expect(driver.get('some_key')).to eq(nil)
          end
        end
      end

      context "when we have NOT passed the expiration" do
        it "returns the cached value" do
          driver = Hitnmiss::InMemoryDriver.new
          cur_time = Time.now.utc
          Timecop.freeze(cur_time) do
            cache = { 'some_key' => { 'value' => 'foo', 'expiration' => (cur_time.to_i + 234232) } }
            driver.instance_variable_set(:@cache, cache)
            expect(driver.get('some_key')).to eq('foo')
          end
        end
      end
    end

    context "when key does not match something cached" do
      it "returns nil indicating a miss" do
        driver = Hitnmiss::InMemoryDriver.new
        cache = { 'some_key' => { 'value' => 'foo', 'expiration' => 23 } }
        driver.instance_variable_set(:@cache, cache)
        expect(driver.get('some_other_key')).to eq(nil)
      end
    end
  end

  describe '#all' do
    it 'returns only the values whose keys begin with the keyspace' do
      driver = Hitnmiss::InMemoryDriver.new
      cache = {
        'keyspace.some_key' => { 'value' => 'foo', 'expiration' => 23 },
        'keyspace.some_other_key' => { 'value' => 'bar', 'expiration' => 33 },
        'notkeyspace.some_key' => { 'value' => 'baz', 'expiration' => 43 }
      }
      driver.instance_variable_set(:@cache, cache)
      expect(driver.all('keyspace')).to match_array(
        [
          { 'value' => 'foo', 'expiration' => 23 },
          { 'value' => 'bar', 'expiration' => 33 }
        ]
      )
    end
  end

  describe '#del' do
    it 'deletes the cached value for the key' do
      driver = Hitnmiss::InMemoryDriver.new
      cache = {
        'keyspace.some_key' => { 'value' => 'foo', 'expiration' => 23 },
        'keyspace.some_other_key' => { 'value' => 'bar', 'expiration' => 33 }
      }
      driver.instance_variable_set(:@cache, cache)
      driver.del('keyspace.some_key')
      expect(cache.has_key?('keyspace.some_key')).to eq false
    end
  end

  describe '#clear' do
    it 'clears the cache' do
      driver = Hitnmiss::InMemoryDriver.new
      cache = {
        'keyspace.some_key' => { 'value' => 'foo', 'expiration' => 23 },
        'keyspace.some_other_key' => { 'value' => 'bar', 'expiration' => 33 },
        'notkeyspace.some_key' => { 'value' => 'baz', 'expiration' => 43 }
      }
      driver.instance_variable_set(:@cache, cache)
      driver.clear('keyspace')
      expect(cache).to eq(
        {
          'notkeyspace.some_key' => { 'value' => 'baz', 'expiration' => 43 }
        }
      )
    end
  end
end
