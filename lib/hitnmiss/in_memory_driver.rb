module Hitnmiss
  class InMemoryDriver
    include Hitnmiss::Driver::Interface

    def initialize
      @mutex = Mutex.new
      @cache = {}
    end

    def set(key, value, expiration_in_seconds)
      expiration = Time.now.utc.to_i + expiration_in_seconds
      @mutex.synchronize do
        @cache[key] = { 'value' => value, 'expiration' => expiration }
      end
    end

    def setnoexp(key, value)
      @mutex.synchronize do
        @cache[key] = { 'value' => value }
      end
    end

    def get(key)
      cached_entity = nil
      @mutex.synchronize do
        cached_entity = @cache[key].dup if @cache[key]
      end

      if cached_entity
        if cached_entity.has_key?('expiration')
          if Time.now.utc.to_i > cached_entity['expiration']
            return Hitnmiss::Driver::Miss.new 
          else
            return Hitnmiss::Driver::Hit.new(cached_entity['value'])
          end
        else
          return Hitnmiss::Driver::Hit.new(cached_entity['value'])
        end
      else
        return Hitnmiss::Driver::Miss.new
      end
    end

    def all(keyspace)
      @mutex.synchronize do
        matching_values = []
        @cache.each do |key, entity|
          matching_values << entity.fetch('value') if match_keyspace?(key, keyspace)
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
  end
end
