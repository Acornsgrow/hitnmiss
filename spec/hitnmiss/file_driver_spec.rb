require 'spec_helper'

describe "Hitnmiss::FileDriver" do
  let(:folder) { File.expand_path("../../support/cache", __FILE__) }
  subject { Hitnmiss::FileDriver.new(folder) }

  before do
    subject
  end

  after do
    Dir["#{folder}/*"].each { |filename| File.unlink(filename) }
  end

  describe ".new" do
    it "sets ths folder to the passed in folder" do
      folder = subject.instance_variable_get(:@folder)
      expect(folder).to match("support/cache")
    end
  end

  describe "#set" do
    context 'when given entity has an expiration' do
      it "caches the given value, using the given key and expiration" do
        entity = Hitnmiss::Entity.new('some_value', expiration: 1)
        now = Time.now.utc
        Timecop.freeze(now) do
          subject.set('some_key', entity)
        end
        cache = JSON.parse(File.read(File.join(folder, "some_key")))
        expect(cache['value']).to eq('some_value')
        expect(cache['expiration']).to eq(now.to_i + 1)
      end
    end

    context 'when given entity has a fingerprint' do
      it 'caches the given value with key, expiration, and fingerprint' do
        entity = Hitnmiss::Entity.new('some_value', expiration: 1,
                                      fingerprint: 'foofingerprint')
        now = Time.now.utc
        Timecop.freeze(now) do
          subject.set('some_key', entity)
        end
        cache = JSON.parse(File.read(File.join(folder, "some_key")))
        expect(cache['value']).to eq('some_value')
        expect(cache['expiration']).to eq(now.to_i + 1)
        expect(cache['fingerprint']).to eq('foofingerprint')
      end
    end

    context 'when given entity has a last_modified' do
      it 'caches the given value with key, expiration, and last_modified' do
        entity = Hitnmiss::Entity.new('some_value', expiration: 1,
                                      fingerprint: 'foofingerprint',
                                      last_modified: '2016-04-14T11:00:00Z')
        now = Time.now.utc
        Timecop.freeze(now) do
          subject.set('some_key', entity)
        end
        cache = JSON.parse(File.read(File.join(folder, "some_key")))
        expect(cache['value']).to eq('some_value')
        expect(cache['expiration']).to eq(now.to_i + 1)
        expect(cache['fingerprint']).to eq('foofingerprint')
        expect(cache['last_modified']).to eq('2016-04-14T11:00:00Z')
      end

      it 'stores the updated_at timestamp in utc iso8601' do
        entity = Hitnmiss::Entity.new('some_value', expiration: 1)
        now = Time.utc(2016, 4, 15, 13, 0, 0)
        Timecop.freeze(now) do
          subject.set('some_key', entity)
        end
        cache = JSON.parse(File.read(File.join(folder, "some_key")))
        expect(cache['updated_at']).to eq('2016-04-15T13:00:00Z')
      end
    end

    context 'when given entity does NOT have an expiration' do
      it 'caches the given value, using the given key' do
        entity = Hitnmiss::Entity.new('some_value')
        subject.set('some_key', entity)
        cache = JSON.parse(File.read(File.join(folder, "some_key")))
        expect(cache['value']).to eq('some_value')
        expect(cache.has_key?('expiration')).to eq(false)
      end

      context 'when given entity has a fingerprint' do
        it 'caches the given value, using the given key and fingerprint' do
          entity = Hitnmiss::Entity.new('some_value', fingerprint: 'some-fingerprint')
          subject.set('some_key', entity)
          cache = JSON.parse(File.read(File.join(folder, "some_key")))
          expect(cache['value']).to eq('some_value')
          expect(cache.has_key?('expiration')).to eq(false)
          expect(cache['fingerprint']).to eq('some-fingerprint')
        end
      end

      context 'when given entity has a last_modified' do
        it 'caches the given value with key, expiration, and last_modified' do
          entity = Hitnmiss::Entity.new('some_value',
                                        fingerprint: 'foofingerprint',
                                        last_modified: '2016-04-14T11:00:00Z')
          now = Time.now.utc
          Timecop.freeze(now) do
            subject.set('some_key', entity)
          end
          cache = JSON.parse(File.read(File.join(folder, "some_key")))
          expect(cache['value']).to eq('some_value')
          expect(cache['fingerprint']).to eq('foofingerprint')
          expect(cache['last_modified']).to eq('2016-04-14T11:00:00Z')
        end
      end

      it 'stores the updated_at timestamp in utc iso8601' do
        entity = Hitnmiss::Entity.new('some_value')
        now = Time.utc(2016, 4, 15, 13, 0, 0)
        Timecop.freeze(now) do
          subject.set('some_key', entity)
        end
        cache = JSON.parse(File.read(File.join(folder, "some_key")))
        expect(cache['updated_at']).to eq('2016-04-15T13:00:00Z')
      end
    end
  end

  describe "#get" do
    context "when key matches something cached" do
      context "when we have passed the expiration" do
        it "returns a Hitnmiss::Driver::Miss indicating a miss" do
          cur_time = Time.now.utc
          Timecop.freeze(cur_time) do
            File.write(File.join(folder, "some_key"), { 'value' => 'foo', 'expiration' => (cur_time.to_i - 423423) }.to_json)
            expect(subject.get('some_key')).to be_a(Hitnmiss::Driver::Miss)
          end
        end
      end

      context "when we have NOT passed the expiration" do
        it "returns a Hitnmiss::Driver::Hit with the cached value" do
          cur_time = Time.now.utc
          Timecop.freeze(cur_time) do
            File.write(File.join(folder, "some_key"), { 'value' => 'foo', 'expiration' => (cur_time.to_i + 234232) }.to_json)
            hit = subject.get('some_key')
            expect(hit).to be_a(Hitnmiss::Driver::Hit)
            expect(hit.value).to eq('foo')
          end
        end
      end
    end

    context "when key does not match something cached" do
      it "returns a Hitnmiss::Driver::Miss indicating a miss" do
        cache = { 'value' => 'foo', 'expiration' => 23 }
        File.write(File.join(folder, "some_key"), cache.to_json)
        expect(subject.get('some_other_key')).to be_a(Hitnmiss::Driver::Miss)
      end
    end
  end

  describe '#all' do
    it 'returns only the values whose keys begin with the keyspace' do
      {
        'keyspace.some_key' => { 'value' => 'foo', 'expiration' => 23 },
        'keyspace.some_other_key' => { 'value' => 'bar', 'expiration' => 33 },
        'notkeyspace.some_key' => { 'value' => 'baz', 'expiration' => 43 }
      }.each {|k,v| File.write(File.join(folder, k), v.to_json) }
      expect(subject.all('keyspace')).to match_array(['foo', 'bar'])
    end
  end

  describe '#del' do
    it 'deletes the cached value for the key' do
      {
        'keyspace.some_key' => { 'value' => 'foo', 'expiration' => 23 },
        'keyspace.some_other_key' => { 'value' => 'bar', 'expiration' => 33 }
      }.each {|k,v| File.write(File.join(folder, k), v.to_json) }
      expect(File.exists?(File.join(folder, 'keyspace.some_key'))).to eq true
      subject.delete('keyspace.some_key')
      expect(File.exists?(File.join(folder, 'keyspace.some_key'))).to eq false
    end
  end

  describe '#clear' do
    it 'clears the cache' do
      {
        'keyspace.some_key' => { 'value' => 'foo', 'expiration' => 23 },
        'keyspace.some_other_key' => { 'value' => 'bar', 'expiration' => 33 },
        'notkeyspace.some_key' => { 'value' => 'baz', 'expiration' => 43 }
      }.each {|k,v| File.write(File.join(folder, k), v.to_json) }
      subject.clear('keyspace')
      expect(File.exists?(File.join(folder, "notkeyspace.some_key"))).to eq true
      expect(File.exists?(File.join(folder, "keyspace.some_key"))).to eq false
      expect(File.exists?(File.join(folder, "keyspace.some_other_key"))).to eq false
    end
  end
end
