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
        entity = Hitnmiss::Entity.new('some_value', expiration: 1)
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
          entity = Hitnmiss::Entity.new('some_value', expiration: 1,
                                        fingerprint: 'foofingerprint')
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

      context 'when given entity has a last_modified' do
        it 'caches the given value with key, expiration, and last_modified' do
          driver = Hitnmiss::InMemoryDriver.new
          entity = Hitnmiss::Entity.new('some_value', expiration: 1,
                                        fingerprint: 'foofingerprint',
                                        last_modified: '2016-04-14T11:00:00Z')
          now = Time.now.utc
          Timecop.freeze(now) do
            driver.set('some_key', entity)
          end
          cache = driver.instance_variable_get(:@cache)
          expect(cache['some_key']['value']).to eq('some_value')
          expect(cache['some_key']['expiration']).to eq(now.to_i + 1)
          expect(cache['some_key']['fingerprint']).to eq('foofingerprint')
          expect(cache['some_key']['last_modified']).to eq('2016-04-14T11:00:00Z')
        end
      end

      it 'stores the updated_at timestamp in utc iso8601' do
        driver = Hitnmiss::InMemoryDriver.new
        entity = Hitnmiss::Entity.new('some_value', expiration: 1)
        now = Time.utc(2016, 4, 15, 13, 0, 0)
        Timecop.freeze(now) do
          driver.set('some_key', entity)
        end
        cache = driver.instance_variable_get(:@cache)
        expect(cache['some_key']['updated_at']).to eq('2016-04-15T13:00:00Z')
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
          entity = Hitnmiss::Entity.new('some_value', fingerprint: 'some-fingerprint')
          driver.set('some_key', entity)
          cache = driver.instance_variable_get(:@cache)
          expect(cache['some_key']['value']).to eq('some_value')
          expect(cache['some_key'].has_key?('expiration')).to eq(false)
          expect(cache['some_key']['fingerprint']).to eq('some-fingerprint')
        end
      end

      context 'when given entity has a last_modified' do
        it 'caches the given value with key, expiration, and last_modified' do
          driver = Hitnmiss::InMemoryDriver.new
          entity = Hitnmiss::Entity.new('some_value',
                                        fingerprint: 'foofingerprint',
                                        last_modified: '2016-04-14T11:00:00Z')
          now = Time.now.utc
          Timecop.freeze(now) do
            driver.set('some_key', entity)
          end
          cache = driver.instance_variable_get(:@cache)
          expect(cache['some_key']['value']).to eq('some_value')
          expect(cache['some_key']['fingerprint']).to eq('foofingerprint')
          expect(cache['some_key']['last_modified']).to eq('2016-04-14T11:00:00Z')
        end
      end

      it 'stores the updated_at timestamp in utc iso8601' do
        driver = Hitnmiss::InMemoryDriver.new
        entity = Hitnmiss::Entity.new('some_value')
        now = Time.utc(2016, 4, 15, 13, 0, 0)
        Timecop.freeze(now) do
          driver.set('some_key', entity)
        end
        cache = driver.instance_variable_get(:@cache)
        expect(cache['some_key']['updated_at']).to eq('2016-04-15T13:00:00Z')
      end
    end
  end

  describe "#get" do
    context "when key matches something cached" do
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

        context 'when has last_modified' do
          it 'returns a Hit with the cached value and last_modified' do
            driver = Hitnmiss::InMemoryDriver.new
            cur_time = Time.now.utc
            Timecop.freeze(cur_time) do
              cache = { 'some_key' => { 'value' => 'foo', 'expiration' => (cur_time.to_i + 234232), 'last_modified' => 'foobar' } }
              driver.instance_variable_set(:@cache, cache)
              hit = driver.get('some_key')
              expect(hit).to be_a(Hitnmiss::Driver::Hit)
              expect(hit.value).to eq('foo')
              expect(hit.last_modified).to eq('foobar')
            end
          end
        end

        context 'when has updated_at' do
          it 'returns a Hit object with updated_at set to time object' do
            driver = Hitnmiss::InMemoryDriver.new
            entity = Hitnmiss::Entity.new('some_value')
            now = Time.utc(2016, 4, 15, 13, 0, 0)
            Timecop.freeze(now) do
              driver.set('some_key', entity)
            end
            hit = driver.get('some_key')
            expect(hit.updated_at).to eq(now)
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
    it 'returns only the values whose keys begin with the keyspace and are not expired' do
      driver = Hitnmiss::InMemoryDriver.new
      cur_time = Time.now.utc
      Timecop.freeze(cur_time) do
        cache = {
          'keyspace.some_key' => { 'value' => 'foo', 'expiration' => 23 },
          'keyspace.some_other_key' => { 'value' => 'bar', 'expiration' => (cur_time.to_i + 234232) },
          'notkeyspace.some_key' => { 'value' => 'baz', 'expiration' => (cur_time.to_i + 234232) }
        }
        driver.instance_variable_set(:@cache, cache)
        expect(driver.all('keyspace')).to match_array(['bar'])
      end
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
