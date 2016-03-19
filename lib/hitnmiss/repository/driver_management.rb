module Hitnmiss
  module Repository
    module DriverManagement
      def self.extended(mod)
        mod.driver :in_memory
      end

      def driver(driver_name=nil)
        if driver_name
          @driver_name = driver_name
        else
          @driver_name
        end
      end
    end
  end
end
