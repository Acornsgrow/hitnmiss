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
  end
end
