require 'spec_helper'

describe Hitnmiss::Repository do
  describe '.default_expiration' do
    context 'when given an expiration' do
      it 'set the default expiration for the cache repository' do
        expiration = double('expiration')
        repo_klass = Class.new do
          include Hitnmiss::Repository

          default_expiration expiration
        end

        actual_default_expiration = repo_klass.instance_variable_get(:@default_expiration)
        expect(actual_default_expiration).to eq(expiration)
      end
    end

    context 'when NOT given an expiration' do
      context 'when default expiration has been set' do
        it 'returns the expiration' do
          expiration = double('expiration')
          repo_klass = Class.new do
            include Hitnmiss::Repository

            default_expiration expiration
          end

          actual_default_expiration = repo_klass.default_expiration
          expect(actual_default_expiration).to eq(expiration)
        end
      end

      context 'when default expiration has NOT been set' do
        it 'returns nil' do
          repo_klass = Class.new do
            include Hitnmiss::Repository
          end

          actual_default_expiration = repo_klass.default_expiration
          expect(actual_default_expiration).to eq(nil)
        end
      end
    end
  end
end
