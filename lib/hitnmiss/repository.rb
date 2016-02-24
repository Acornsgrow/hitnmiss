module Hitnmiss
  module Repository
    KEY_COMPONENT_SEPARATOR = '.'.freeze
    KEY_COMPONENT_TYPE_SEPARATOR = ':'.freeze

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

      def keyspace
        name
      end

      def generate_key(*args)
        components = args.map do |arg|
          "#{arg.class.name}#{KEY_COMPONENT_TYPE_SEPARATOR}#{arg}"
        end
        return "#{keyspace}#{KEY_COMPONENT_SEPARATOR}" \
               "#{components.join(KEY_COMPONENT_SEPARATOR)}"
      end

      def get(*args)
        raise Hitnmiss::Errors::NotImplemented
      end

      def get_all(keyspace)
        raise Hitnmiss::Errors::NotImplemented
      end

      def prime(*args)
        cacheable_entity = get(*args)
        cache_entity(args, cacheable_entity)
        return cacheable_entity.value
      end

      def prime_all
        cacheable_entities = get_all(keyspace)
        cacheable_entities.each do |cacheable_entity_hash|
          args = cacheable_entity_hash.fetch(:args)
          cacheable_entity = cacheable_entity_hash.fetch(:entity)
          cache_entity(args, cacheable_entity)
        end
      end

      def fetch(*args)
        value = Hitnmiss.driver(@driver_name).get(generate_key(*args))
        if value.nil?
          return prime(*args)
        else
          return value
        end
      end

      def delete(*args)
        Hitnmiss.driver(@driver_name).delete(generate_key(*args))
      end

      def all
        Hitnmiss.driver(@driver_name).all(keyspace)
      end

      private

      def cache_entity(args, cacheable_entity)
        if cacheable_entity.expiration
          Hitnmiss.driver(@driver_name).set(generate_key(*args), cacheable_entity.value,
                     cacheable_entity.expiration)
        else
          Hitnmiss.driver(@driver_name).set(generate_key(*args), cacheable_entity.value,
                     @default_expiration)
        end
      end
    end
  end
end
