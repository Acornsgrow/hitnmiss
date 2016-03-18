require 'spec_helper'

describe Hitnmiss::DriverRegistry do
  describe "#initialize" do
    it "creates a new registry hash" do
      expect(subject.instance_variable_get(:@registry)).to eq({})
    end
  end

  describe "#register" do
    it "adds the driver to the registry hash" do
      registry = double('registry')
      name = double('name')
      driver = double('driver')
      subject.instance_variable_set(:@registry, registry)
      expect(registry).to receive(:[]=).with(name, driver)
      subject.register(name, driver)
    end
  end

  describe "#get" do
    context "when the driver is registerd in the registry" do
      it "returns the driver" do
        name = double('name')
        driver = double('driver')
        subject.register(name, driver)
        expect(subject.get(name)).to eq(driver)
      end
    end

    context "when the driver is not registered in the registry" do
      it "raises an UnregisteredDriver exception" do
        expect { subject.get("name") }.to raise_error(Hitnmiss::Errors::UnregisteredDriver)
      end
    end
  end
end
