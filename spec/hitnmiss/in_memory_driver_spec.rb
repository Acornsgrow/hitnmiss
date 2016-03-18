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
    context 'when given entity has an expiration' do
      it "caches the given value, using the given key and expiration" do
        driver = Hitnmiss::InMemoryDriver.new
        entity = Hitnmiss::Entity.new('some_value', 1)
        now = Time.now.utc
        Timecop.freeze(now) do
          driver.set('some_key', entity)
        end
        cache = driver.instance_variable_get(:@cache)
        expect(cache['some_key']['value']).to eq('some_value')
        expect(cache['some_key']['expiration']).to eq(now.to_i + 1)
      end

      context 'when given entity has a fingerprint' do
        it 'caches the given value with key, expiration, and fingerprint' do
          driver = Hitnmiss::InMemoryDriver.new
          entity = Hitnmiss::Entity.new('some_value', 1, 'foofingerprint')
          now = Time.now.utc
          Timecop.freeze(now) do
            driver.set('some_key', entity)
          end
          cache = driver.instance_variable_get(:@cache)
          expect(cache['some_key']['value']).to eq('some_value')
          expect(cache['some_key']['expiration']).to eq(now.to_i + 1)
          expect(cache['some_key']['fingerprint']).to eq('foofingerprint')
        end
      end
    end

    context 'when given entity does NOT have an expiration' do
      it 'caches the given value, using the given key' do
        driver = Hitnmiss::InMemoryDriver.new
        entity = Hitnmiss::Entity.new('some_value')
        driver.set('some_key', entity)
        cache = driver.instance_variable_get(:@cache)
        expect(cache['some_key']['value']).to eq('some_value')
        expect(cache['some_key'].has_key?('expiration')).to eq(false)
      end

      context 'when given entity has a fingerprint' do
        it 'caches the given value, using the given key and fingerprint' do
          driver = Hitnmiss::InMemoryDriver.new
          entity = Hitnmiss::Entity.new('some_value', nil, 'some-fingerprint')
          driver.set('some_key', entity)
          cache = driver.instance_variable_get(:@cache)
          expect(cache['some_key']['value']).to eq('some_value')
          expect(cache['some_key'].has_key?('expiration')).to eq(false)
          expect(cache['some_key']['fingerprint']).to eq('some-fingerprint')
        end
      end
    end
  end

  describe "#get" do
    context "when key matches something cached" do
      context "when expiration exists" do
        context "when we have passed the expiration" do
          it "returns a Hitnmiss::Driver::Miss indicating a miss" do
            driver = Hitnmiss::InMemoryDriver.new
            cur_time = Time.now.utc
            Timecop.freeze(cur_time) do
              cache = { 'some_key' => { 'value' => 'foo', 'expiration' => (cur_time.to_i - 423423) } }
              driver.instance_variable_set(:@cache, cache)
              expect(driver.get('some_key')).to be_a(Hitnmiss::Driver::Miss)
            end
          end
        end

        context "when we have NOT passed the expiration" do
          it "returns a Hitnmiss::Driver::Hit with the cached value" do
            driver = Hitnmiss::InMemoryDriver.new
            cur_time = Time.now.utc
            Timecop.freeze(cur_time) do
              cache = { 'some_key' => { 'value' => 'foo', 'expiration' => (cur_time.to_i + 234232) } }
              driver.instance_variable_set(:@cache, cache)
              hit = driver.get('some_key')
              expect(hit).to be_a(Hitnmiss::Driver::Hit)
              expect(hit.value).to eq('foo')
            end
          end

          context 'when has a fingerprint' do
            it 'returns a Hit with the cached value and fingerprint' do
              driver = Hitnmiss::InMemoryDriver.new
              cur_time = Time.now.utc
              Timecop.freeze(cur_time) do
                cache = { 'some_key' => { 'value' => 'foo', 'expiration' => (cur_time.to_i + 234232), 'fingerprint' => 'foobar' } }
                driver.instance_variable_set(:@cache, cache)
                hit = driver.get('some_key')
                expect(hit).to be_a(Hitnmiss::Driver::Hit)
                expect(hit.value).to eq('foo')
                expect(hit.fingerprint).to eq('foobar')
              end
            end
          end
        end
      end

      context "when expiration does NOT exist" do
        it "returns a Hitnmiss::Driver::Hit with the cached value" do
          driver = Hitnmiss::InMemoryDriver.new
          cache = { 'some_key' => { 'value' => 'foo' } }
          driver.instance_variable_set(:@cache, cache)
          hit = driver.get('some_key')
          expect(hit).to be_a(Hitnmiss::Driver::Hit)
          expect(hit.value).to eq('foo')
        end

        context 'when has a fingerprint' do
          it 'returns a Hit with the cached value and fingerprint' do
            driver = Hitnmiss::InMemoryDriver.new
            cache = { 'some_key' => { 'value' => 'foo', 'fingerprint' => 'foobar' } }
            driver.instance_variable_set(:@cache, cache)
            hit = driver.get('some_key')
            expect(hit).to be_a(Hitnmiss::Driver::Hit)
            expect(hit.value).to eq('foo')
            expect(hit.fingerprint).to eq('foobar')
          end
        end
      end
    end

    context "when key does not match something cached" do
      it "returns a Hitnmiss::Driver::Miss indicating a miss" do
        driver = Hitnmiss::InMemoryDriver.new
        cache = { 'some_key' => { 'value' => 'foo', 'expiration' => 23 } }
        driver.instance_variable_set(:@cache, cache)
        expect(driver.get('some_other_key')).to be_a(Hitnmiss::Driver::Miss)
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
      expect(driver.all('keyspace')).to match_array(['foo', 'bar'])
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
      driver.delete('keyspace.some_key')
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
