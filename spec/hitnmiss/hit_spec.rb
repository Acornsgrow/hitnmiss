require 'spec_helper'

describe Hitnmiss::Hit do
  describe '.new' do
    context 'when given a value' do
      it 'constructs an instance of Hitnmiss::Hit' do
        value = double('value')
        hit = Hitnmiss::Hit.new(value)
        expect(hit).to be_a(Hitnmiss::Hit)
      end
    end
  end

  describe "#value" do
    it "returns its initialized value" do
      value = double('value')
      hit = Hitnmiss::Hit.new(value)
      expect(hit.value).to eq(value)
    end
  end
end
