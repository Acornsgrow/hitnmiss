require 'spec_helper'

describe Hitnmiss::Miss do
  describe '.new' do
    it 'constructs an instance of Hitnmiss::Hit' do
      miss = Hitnmiss::Miss.new
      expect(miss).to be_a(Hitnmiss::Miss)
    end
  end
end
