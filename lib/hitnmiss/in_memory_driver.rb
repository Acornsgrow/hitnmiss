module Hitnmiss
  class InMemoryDriver < Hitnmiss::Driver
    def initialize
      @cache = {}
    end

    def set(key, value, expiration_in_seconds)
      expiration = Time.now.utc.to_i + expiration_in_seconds
      @cache[key] = { 'value' => value, 'expiration' => expiration }
    end

    def get(key)
      if @cache[key]
        if Time.now.utc.to_i > @cache[key]['expiration']
          return nil
        else
          return @cache[key]['value']
        end
      else
        return nil
      end
    end
  end
end
