module Hitnmiss
  module Repository
    def self.included(mod)
      mod.extend(ClassMethods)
    end

    module ClassMethods
      def driver(driver)
        @driver = driver
      end

      def default_expiration(expiration_in_seconds)
        @default_expiration = expiration_in_seconds
      end

      def generate_key(*args)
        components = args.map do |arg|
          "#{arg.class.name}:#{arg}"
        end
        return "#{name}.#{components.join('.')}"
      end

      def perform(*args)
        raise Hitnmiss::Errors::NotImplemented
      end

      def prime_cache(*args)
        cacheable_entity = perform(*args)
        if cacheable_entity.expiration
          @driver.set(generate_key(*args), cacheable_entity.value,
                     cacheable_entity.expiration)
        else
          @driver.set(generate_key(*args), cacheable_entity.value,
                     @default_expiration)
        end
        return cacheable_entity.value
      end

      def fetch(*args)
        if value = @driver.get(generate_key(*args))
          return value
        else
          return prime_cache(*args)
        end
      end
    end
  end
end
