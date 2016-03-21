require 'spec_helper'

describe Hitnmiss::Driver do
  describe Hitnmiss::Driver::Hit do
    describe '.new' do
      context 'when given a value' do
        it 'constructs an instance of Hitnmiss::Driver::Hit' do
          value = double('value')
          hit = Hitnmiss::Driver::Hit.new(value)
          expect(hit).to be_a(Hitnmiss::Driver::Hit)
        end
      end
    end

    describe "#value" do
      it "returns its initialized value" do
        value = double('value')
        hit = Hitnmiss::Driver::Hit.new(value)
        expect(hit.value).to eq(value)
      end
    end

    describe '#updated_at' do
      context 'when constructed with an updated_at' do
        it 'returns the timestamp it was last updated' do
          value = double('value')
          updated_at = double('updated_at')
          hit = Hitnmiss::Driver::Hit.new(value, updated_at: updated_at)
          expect(hit.updated_at).to eq(updated_at)
        end
      end

      context 'when constructed without an updated_at' do
        it 'returns nil' do
          value = double('value')
          hit = Hitnmiss::Driver::Hit.new(value)
          expect(hit.updated_at).to be_nil
        end
      end
    end

    describe '#fingerprint' do
      context 'when constructed with a fingerprint' do
        it 'returns the fingerprint' do
          value = double('value')
          fingerprint = double('fingerprint')
          hit = Hitnmiss::Driver::Hit.new(value, fingerprint: fingerprint)
          expect(hit.fingerprint).to eq(fingerprint)
        end
      end

      context 'when constructed without a fingerprint' do
        it 'returns the nil' do
          value = double('value')
          hit = Hitnmiss::Driver::Hit.new(value)
          expect(hit.fingerprint).to be_nil
        end
      end
    end

    describe '#last_modified' do
      context 'when constructed with last_modified' do
        it 'returns the last_modified' do
          value = double('value')
          last_modified = double('last_modified')
          hit = Hitnmiss::Driver::Hit.new(value, last_modified: last_modified)
          expect(hit.last_modified).to eq(last_modified)
        end
      end

      context 'when constructed without a last_modified' do
        it 'returns the nil' do
          value = double('value')
          hit = Hitnmiss::Driver::Hit.new(value)
          expect(hit.last_modified).to be_nil
        end
      end
    end
  end

  describe Hitnmiss::Driver::Miss do
    describe '.new' do
      it 'constructs an instance of Hitnmiss::Driver::Miss' do
        miss = Hitnmiss::Driver::Miss.new
        expect(miss).to be_a(Hitnmiss::Driver::Miss)
      end
    end
  end

  describe Hitnmiss::Driver::Interface do
    subject { Class.new.class.include Hitnmiss::Driver::Interface }

    describe "#set" do
      it "raises error indicating not implemented" do
        expect { subject.set(double('key'),
                             double('entity')) }.to \
        raise_error(Hitnmiss::Errors::NotImplemented)
      end
    end

    describe "#get" do
      it "raises error indicating not implemented" do
        expect { subject.get(double('key')) }.to \
        raise_error(Hitnmiss::Errors::NotImplemented)
      end
    end

    describe '#all' do
      it "raises error indicating not implemented" do
        expect { subject.all(double('key namespace')) }.to \
        raise_error(Hitnmiss::Errors::NotImplemented)
      end
    end

    describe '#delete' do
      it "raises error indicating not implemented" do
        expect { subject.delete(double('key')) }.to \
        raise_error(Hitnmiss::Errors::NotImplemented)
      end
    end

    describe '#clear' do
      it "raises error indicating not implemented" do
        expect { subject.clear(double('key namespace')) }.to \
        raise_error(Hitnmiss::Errors::NotImplemented)
      end
    end
  end
end
