module Hitnmiss
  class InMemoryDriver < Hitnmiss::Driver
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

    def get(key)
      cached_entity = nil
      @mutex.synchronize do
        cached_entity = @cache[key].dup if @cache[key]
      end

      if cached_entity
        if Time.now.utc.to_i > cached_entity['expiration']
          return nil
        else
          return cached_entity['value']
        end
      else
        return nil
      end
    end
  end
end
