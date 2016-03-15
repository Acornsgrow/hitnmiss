require 'spec_helper'

RSpec.describe Hitnmiss::Repository::DriverManagement do
  describe '.driver' do
    context 'when given a driver identifier' do
      it 'sets driver to a registered driver' do
        repo_klass = Class.new do
          extend Hitnmiss::Repository::DriverManagement
          driver :some_driver
        end

        driver_name = repo_klass.instance_variable_get(:@driver_name)
        expect(driver_name).to eq(:some_driver)
      end
    end

    context 'when NOT given a driver identifier' do
      context 'when driver has been set' do
        it 'returns the driver identifier' do
          repo_klass = Class.new do
            extend Hitnmiss::Repository::DriverManagement
            driver :some_driver
          end

          driver_name = repo_klass.driver
          expect(driver_name).to eq(:some_driver)
        end
      end

      context 'when driver has NOT been set' do
        it 'returns identifier for the default driver' do
          repo_klass = Class.new do
            extend Hitnmiss::Repository::DriverManagement
          end

          driver_name = repo_klass.driver
          expect(driver_name).to eq(:in_memory)
        end
      end
    end
  end
end
