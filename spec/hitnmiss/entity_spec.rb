require 'spec_helper'

describe Hitnmiss::Entity do
  describe ".new" do
    context "when given a value and expiration" do
      it "constructs an instance of Hitnmiss::Entity" do
        value = double('value')
        exp_in_secs = double('expiration in secs')
        entity = Hitnmiss::Entity.new(value, exp_in_secs)
        expect(entity).to be_a(Hitnmiss::Entity)
      end
    end

    context "when given only a value" do
      it "constructs an instance of Hitnmiss::Entity" do
        value = double('value')
        entity = Hitnmiss::Entity.new(value)
        expect(entity).to be_a(Hitnmiss::Entity)
      end

      it "sets the expiration to nil" do
        value = double('value')
        entity = Hitnmiss::Entity.new(value)
        expect(entity.expiration).to be_nil
      end
    end
  end

  describe "#value" do
    it "returns its initialized value" do
      value = double('value')
      exp_in_secs = double('expiration in secs')
      entity = Hitnmiss::Entity.new(value, exp_in_secs)
      expect(entity.value).to eq(value)
    end
  end

  describe "#expiration" do
    it "returns its initialized expiration" do
      value = double('value')
      exp_in_secs = double('expiration in secs')
      entity = Hitnmiss::Entity.new(value, exp_in_secs)
      expect(entity.expiration).to eq(exp_in_secs)
    end
  end

  describe '#fingerprint' do
    context 'when constructed with a fingerprint' do
      context 'when constructed with an expiration' do
        it 'returns the fingerprint' do
          value = double('value')
          expiration = double('expiration')
          fingerprint = double('fingerprint')
          entity = Hitnmiss::Entity.new(value, expiration, fingerprint)
          expect(entity.fingerprint).to eq(fingerprint)
        end
      end

      context 'when constructed without an expiration' do
        it 'returns the fingerprint' do
          value = double('value')
          fingerprint = double('fingerprint')
          entity = Hitnmiss::Entity.new(value, nil, fingerprint)
          expect(entity.fingerprint).to eq(fingerprint)
        end
      end
    end

    context 'when constructed without a fingerprint' do
      it 'returns nil' do
        value = double('value')
        entity = Hitnmiss::Entity.new(value)
        expect(entity.fingerprint).to be_nil
      end
    end
  end
end
