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
end
