module Hitnmiss
  class Entity
    attr_reader :value, :expiration, :fingerprint

    def initialize(value, expiration_in_seconds=nil, fingerprint=nil)
      @value = value
      @expiration = expiration_in_seconds
      @fingerprint = fingerprint
    end
  end
end
