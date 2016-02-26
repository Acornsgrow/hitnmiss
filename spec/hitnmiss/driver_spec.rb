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
                             double('value'),
                             double('expiration')) }.to \
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
