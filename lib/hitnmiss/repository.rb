module Hitnmiss
  module Repository
    KEY_COMPONENT_SEPARATOR = '.'.freeze
    KEY_COMPONENT_TYPE_SEPARATOR = ':'.freeze

    def self.included(mod)
      mod.extend(ClassMethods)
      mod.include(InstanceMethods)
      mod.driver :in_memory
    end

    module ClassMethods
      def driver(driver_name=nil)
        if driver_name
          @driver_name = driver_name
        else
          @driver_name
        end
      end

      def default_expiration(expiration_in_seconds=nil)
        if expiration_in_seconds
          @default_expiration = expiration_in_seconds
        else
          @default_expiration 
        end
      end

      def keyspace
        name
      end
    end

    module InstanceMethods
      def clear
        Hitnmiss.driver(self.class.driver).clear(self.class.keyspace)
      end

      def delete(*args)
        Hitnmiss.driver(self.class.driver).delete(generate_key(*args))
      end

      def all
        Hitnmiss.driver(self.class.driver).all(self.class.keyspace)
      end

      def prime_all
        cacheable_entities = get_all(self.class.keyspace)
        return cacheable_entities.map do |cacheable_entity_hash|
          args = cacheable_entity_hash.fetch(:args)
          cacheable_entity = cacheable_entity_hash.fetch(:entity)
          cache_entity(args, cacheable_entity)
          cacheable_entity.value
        end
      end

      def fetch(*args)
        value = Hitnmiss.driver(self.class.driver).get(generate_key(*args))
        if value.nil?
          return prime(*args)
        else
          return value
        end
      end

      def prime(*args)
        cacheable_entity = get(*args)
        cache_entity(args, cacheable_entity)
        return cacheable_entity.value
      end

      def get(*args)
        raise Hitnmiss::Errors::NotImplemented
      end

      def get_all(keyspace)
        raise Hitnmiss::Errors::NotImplemented
      end

      private

      def cache_entity(args, cacheable_entity)
        if cacheable_entity.expiration
          Hitnmiss.driver(self.class.driver).set(generate_key(*args), cacheable_entity.value,
                     cacheable_entity.expiration)
        else
          Hitnmiss.driver(self.class.driver).set(generate_key(*args), cacheable_entity.value,
                     self.class.default_expiration)
        end
      end

      def generate_key(*args)
        components = args.map do |arg|
          "#{arg.class.name}#{KEY_COMPONENT_TYPE_SEPARATOR}#{arg}"
        end
        return "#{self.class.keyspace}#{KEY_COMPONENT_SEPARATOR}" \
               "#{components.join(KEY_COMPONENT_SEPARATOR)}"
      end
    end
  end
end
