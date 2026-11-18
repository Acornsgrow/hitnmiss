require 'spec_helper'

describe Hitnmiss::Repository do
  describe '#logger' do
    it 'sets the logger using optional logger' do
      mylogger = double('my logger')

      repo_klass = Class.new do
        include Hitnmiss::Repository
      end
      repo = repo_klass.new
      repo.logger(mylogger)

      expect(repo.logger).to be_a(OptionalLogger::Logger)
      expect(repo.logger.wrapped_logger).to eq(mylogger)
    end
  end

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

  describe 'Ruby 3 keyword argument forwarding' do
    it 'passes keyword arguments from #get through to #fetch' do
      repo_klass = Class.new do
        include Hitnmiss::Repository

        default_expiration 60

        attr_reader :received_args, :received_kwargs

        def fetch(*args, **kwargs)
          @received_args = args
          @received_kwargs = kwargs
          Hitnmiss::Entity.new('some-value')
        end
      end

      allow(repo_klass).to receive(:name).and_return('KwargForwarding1')

      repository = repo_klass.new
      repository.get(ids: [1, 2])

      expect(repository.received_args).to eq([])
      expect(repository.received_kwargs).to eq(ids: [1, 2])
    end

    it 'produces the same cache key whether the caller uses a kwarg or a positional Hash' do
      repo_klass = Class.new do
        include Hitnmiss::Repository

        default_expiration 60

        def fetch(*args, **kwargs)
          Hitnmiss::Entity.new('some-value')
        end
      end

      allow(repo_klass).to receive(:name).and_return('KwargForwarding2')

      repository = repo_klass.new

      kwarg_key = repository.send(:generate_key, ids: [1])
      positional_hash_key = repository.send(:generate_key, { ids: [1] })

      expect(kwarg_key).to eq(positional_hash_key)
    end

    it 'supports a mix of positional and keyword arguments' do
      repo_klass = Class.new do
        include Hitnmiss::Repository

        default_expiration 60

        attr_reader :received_args, :received_kwargs

        def fetch(*args, **kwargs)
          @received_args = args
          @received_kwargs = kwargs
          Hitnmiss::Entity.new('mixed')
        end
      end

      allow(repo_klass).to receive(:name).and_return('KwargForwarding3')

      repository = repo_klass.new
      repository.get('user-42', scope: :full)

      expect(repository.received_args).to eq(['user-42'])
      expect(repository.received_kwargs).to eq(scope: :full)
    end
  end
end
