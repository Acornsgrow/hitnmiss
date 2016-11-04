require "optional_logger"
require "hitnmiss/version"
require "hitnmiss/errors"
require "hitnmiss/repository"
require "hitnmiss/background_refresh_repository"
require "hitnmiss/driver_registry"
require "hitnmiss/entity"
require "hitnmiss/driver"
require "hitnmiss/in_memory_driver"
require "hitnmiss/file_driver"

module Hitnmiss
  @driver_registry = DriverRegistry.new

  def self.register_driver(name, driver)
    @driver_registry.register(name, driver)
  end

  def self.driver(name)
    @driver_registry.get(name)
  end
end

Hitnmiss.register_driver(:in_memory, Hitnmiss::InMemoryDriver.new)
