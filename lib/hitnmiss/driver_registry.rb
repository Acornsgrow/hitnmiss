module Hitnmiss
  class DriverRegistry
    def initialize
      @registry = {}
    end

    def register(name, driver)
      @registry[name] = driver
    end

    def get(name)
      @registry.fetch(name) do |name|
        raise Errors::UnregisteredDriver.new("#{name} is not a registered driver")
      end
    end
  end
end
