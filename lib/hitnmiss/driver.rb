module Hitnmiss
  class Driver
    def set(key, value, expiration_in_seconds)
      raise Hitnmiss::Errors::NotImplemented
    end

    def get(key)
      raise Hitnmiss::Errors::NotImplemented
    end
  end
end
