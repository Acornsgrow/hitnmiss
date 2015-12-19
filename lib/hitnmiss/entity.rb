module Hitnmiss
  class Entity
    attr_reader :value, :expiration

    def initialize(value, expiration_in_seconds=nil)
      @value = value
      @expiration = expiration_in_seconds
    end
  end
end
