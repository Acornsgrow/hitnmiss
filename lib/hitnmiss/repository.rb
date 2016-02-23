module Hitnmiss
  module Repository
    def self.included(mod)
      mod.extend(ClassMethods)
      mod.driver :in_memory
    end

    module ClassMethods
      def driver(driver_name)
        @driver_name = driver_name
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
          Hitnmiss.driver(@driver_name).set(generate_key(*args), cacheable_entity.value,
                     cacheable_entity.expiration)
        else
          Hitnmiss.driver(@driver_name).set(generate_key(*args), cacheable_entity.value,
                     @default_expiration)
        end
        return cacheable_entity.value
      end

      def fetch(*args)
        value = Hitnmiss.driver(@driver_name).get(generate_key(*args))
        if value.nil?
          return prime_cache(*args)
        else
          return value
        end
      end
    end
  end
end
