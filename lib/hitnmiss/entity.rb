module Hitnmiss
  class Entity
    attr_reader :value, :expiration, :fingerprint, :last_modified

    def initialize(value, expiration: nil, fingerprint: nil, last_modified: nil)
      @value = value
      @expiration = expiration
      @fingerprint = fingerprint
      @last_modified = last_modified
    end
  end
end
