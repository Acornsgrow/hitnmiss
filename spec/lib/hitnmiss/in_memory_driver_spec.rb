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
end
