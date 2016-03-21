require 'spec_helper'

describe Hitnmiss::Entity do
  describe ".new" do
    context "when given only a value" do
      it "constructs an instance of Hitnmiss::Entity" do
        value = double('value')
        entity = Hitnmiss::Entity.new(value)
        expect(entity).to be_a(Hitnmiss::Entity)
        expect(entity.value).to eq(value)
      end

      it "sets the expiration to nil" do
        value = double('value')
        entity = Hitnmiss::Entity.new(value)
        expect(entity.expiration).to be_nil
      end

      it 'sets the fingerprint to nil' do
        value = double('value')
        entity = Hitnmiss::Entity.new(value)
        expect(entity.fingerprint).to be_nil
      end

      it 'sets the last_modified to nil' do
        value = double('value')
        entity = Hitnmiss::Entity.new(value)
        expect(entity.last_modified).to be_nil
      end
    end

    context "when given a value and expiration" do
      it "constructs an instance of Hitnmiss::Entity" do
        value = double('value')
        exp_in_secs = double('expiration in secs')
        entity = Hitnmiss::Entity.new(value, expiration: exp_in_secs)
        expect(entity).to be_a(Hitnmiss::Entity)
        expect(entity.value).to eq(value)
        expect(entity.expiration).to eq(exp_in_secs)
      end
    end

    context "when given a value and fingerprint" do
      it "constructs an instance of Hitnmiss::Entity" do
        value = double('value')
        fingerprint = double('fingerprint')
        entity = Hitnmiss::Entity.new(value, fingerprint: fingerprint)
        expect(entity).to be_a(Hitnmiss::Entity)
        expect(entity.value).to eq(value)
        expect(entity.fingerprint).to eq(fingerprint)
      end
    end

    context 'when given a value and last_modified' do
      it 'constructs an instance of Hitnmiss::Entity' do
        value = double('value')
        last_modified = double('last_modified')
        entity = Hitnmiss::Entity.new(value, last_modified: last_modified)
        expect(entity).to be_a(Hitnmiss::Entity)
        expect(entity.value).to eq(value)
        expect(entity.last_modified).to eq(last_modified)
      end
    end

    context 'when given a value, expiration, and fingerprint' do
      it 'constructs an instance of Hitnmiss::Entity' do
        value = double('value')
        exp_in_secs = double('expiration in secs')
        fingerprint = double('fingerprint')
        entity = Hitnmiss::Entity.new(value, expiration: exp_in_secs, fingerprint: fingerprint)
        expect(entity).to be_a(Hitnmiss::Entity)
        expect(entity.value).to eq(value)
        expect(entity.expiration).to eq(exp_in_secs)
        expect(entity.fingerprint).to eq(fingerprint)
      end
    end

    context 'when given a value, expiration, fingerprint, and last_modified' do
      it 'constructs an instance of Hitnmiss::Entity' do
        value = double('value')
        exp_in_secs = double('expiration in secs')
        fingerprint = double('fingerprint')
        last_modified = double('last_modified')
        entity = Hitnmiss::Entity.new(value, expiration: exp_in_secs,
                                      fingerprint: fingerprint,
                                      last_modified: last_modified)
        expect(entity).to be_a(Hitnmiss::Entity)
        expect(entity.value).to eq(value)
        expect(entity.expiration).to eq(exp_in_secs)
        expect(entity.fingerprint).to eq(fingerprint)
        expect(entity.last_modified).to eq(last_modified)
      end
    end
  end
end
