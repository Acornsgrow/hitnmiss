require 'spec_helper'

RSpec.describe Hitnmiss::Repository::Fetcher do
  describe '#fetch' do
    it 'raises error indicating not implemented' do
      repo_klass = Class.new do
        include Hitnmiss::Repository::Fetcher
      end

      expect { repo_klass.new.send(:fetch) }.to raise_error(Hitnmiss::Errors::NotImplemented)
    end
  end

  describe '#fetch_all' do
    it 'raises error indicating not implemented' do
      repo_klass = Class.new do
        include Hitnmiss::Repository::Fetcher
      end

      keyspace = double('keyspace')
      expect { repo_klass.new.send(:fetch_all, keyspace) }.to raise_error(Hitnmiss::Errors::NotImplemented)
    end
  end
end
