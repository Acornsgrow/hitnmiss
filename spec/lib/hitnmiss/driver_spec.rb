require 'spec_helper'

describe Hitnmiss::Driver do
  it "constructs an instance of Hitnmiss::Driver" do
    expect(subject).to be_a(Hitnmiss::Driver)
  end

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

  describe '#del' do
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
