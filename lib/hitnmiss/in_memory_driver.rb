module Hitnmiss
  class InMemoryDriver
    include Hitnmiss::Driver::Interface

    def initialize
      @mutex = Mutex.new
      @cache = {}
    end

    def set(key, entity)
      if entity.expiration
        expiration = epoch_time + entity.expiration
        @mutex.synchronize do
          @cache[key] = { 'value' => entity.value, 'expiration' => expiration }
          @cache[key]['fingerprint'] = entity.fingerprint if entity.fingerprint
          @cache[key]['updated_at'] = internal_timestamp
          @cache[key]['last_modified'] = entity.last_modified if entity.last_modified
        end
      else
        @mutex.synchronize do
          @cache[key] = { 'value' => entity.value }
          @cache[key]['fingerprint'] = entity.fingerprint if entity.fingerprint
          @cache[key]['updated_at'] = internal_timestamp
          @cache[key]['last_modified'] = entity.last_modified if entity.last_modified
        end
      end
    end

    def get(key)
      cached_entity = nil
      @mutex.synchronize do
        cached_entity = @cache[key].dup if @cache[key]
      end

      return Hitnmiss::Driver::Miss.new if cached_entity.nil? || expired?(cached_entity)

      return Hitnmiss::Driver::Hit.new(cached_entity['value'],
                                       **build_hit_keyword_args(cached_entity))
    end

    def expired?(entity)
      entity.has_key?('expiration') && epoch_time >= entity['expiration']
    end

    def all(keyspace)
      @mutex.synchronize do
        matching_values = []
        @cache.each do |key, entity|
          matching_values << entity.fetch('value') if match_keyspace?(key, keyspace) && !expired?(entity)
        end
        return matching_values
      end
    end

    def delete(key)
      @mutex.synchronize do
        @cache.delete(key)
      end
    end

    def clear(keyspace)
      @mutex.synchronize do
        @cache.delete_if { |key, _| match_keyspace?(key, keyspace) }
      end
    end

    def match_keyspace?(key, keyspace)
      regex = Regexp.new("^#{keyspace}\\" + Repository::KeyGeneration::KEY_COMPONENT_SEPARATOR)
      return regex.match(key)
    end

    private

    def epoch_time
      Time.now.utc.to_i
    end

    def internal_timestamp
      Time.now.utc.iso8601
    end

    def build_hit_keyword_args(cached_entity)
      options = {}
      if cached_entity.has_key?('fingerprint')
        options[:fingerprint] = cached_entity['fingerprint']
      end
      if cached_entity.has_key?('updated_at')
        options[:updated_at] = Time.parse(cached_entity['updated_at'])
      end
      if cached_entity.has_key?('last_modified')
        options[:last_modified] = cached_entity['last_modified']
      end
      return options
    end
  end
end
