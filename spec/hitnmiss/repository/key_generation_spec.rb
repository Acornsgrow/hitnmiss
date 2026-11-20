require 'spec_helper'

RSpec.describe Hitnmiss::Repository::KeyGeneration do
  describe '#generate_key' do
    it 'generates a key from the class and the given arguments' do
      repo_klass = Class.new do
        include Hitnmiss::Repository::KeyGeneration
      end

      allow(repo_klass).to receive(:name).and_return('HooptyJack')

      repository = repo_klass.new

      expect(repository.send(:generate_key, 'true', true, 1, 'zar')).to \
        eq('HooptyJack.String:true.TrueClass:true.Integer:1.String:zar')
    end

    context 'when called with keyword arguments' do
      it 'folds the keywords into a trailing Hash so the key matches the pre-Ruby-3 layout' do
        repo_klass = Class.new do
          include Hitnmiss::Repository::KeyGeneration
        end

        allow(repo_klass).to receive(:name).and_return('HooptyJack')

        repository = repo_klass.new

        kwarg_key = repository.send(:generate_key, ids: [1])
        positional_hash_key = repository.send(:generate_key, { ids: [1] })

        expect(kwarg_key).to eq(positional_hash_key)
        expect(kwarg_key).to eq('HooptyJack.Hash:{:ids=>[1]}') if RUBY_VERSION < '3.4'
      end

      it 'appends kwargs after positional args' do
        repo_klass = Class.new do
          include Hitnmiss::Repository::KeyGeneration
        end

        allow(repo_klass).to receive(:name).and_return('HooptyJack')

        repository = repo_klass.new

        mixed_key = repository.send(:generate_key, 'foo', ids: [1])
        legacy_key = repository.send(:generate_key, 'foo', { ids: [1] })

        expect(mixed_key).to eq(legacy_key)
      end
    end
  end
end
