require 'hitnmiss/repository/fetcher'
require 'hitnmiss/repository/driver_management'
require 'hitnmiss/repository/key_generation'

module Hitnmiss
  module Repository
    class UnsupportedDriverResponse < StandardError; end

    def self.included(mod)
      mod.extend(DriverManagement)
      mod.include(KeyGeneration)
      mod.include(Fetcher)
      mod.extend(ClassMethods)
      mod.include(InstanceMethods)
    end

    module ClassMethods
      def default_expiration(expiration_in_seconds=nil)
        if expiration_in_seconds
          @default_expiration = expiration_in_seconds
        else
          @default_expiration 
        end
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
        cacheable_entities = fetch_all(self.class.keyspace)
        return cacheable_entities.map do |cacheable_entity_hash|
          args = cacheable_entity_hash.fetch(:args)
          cacheable_entity = cacheable_entity_hash.fetch(:entity)
          cache_entity(args, cacheable_entity)
          cacheable_entity.value
        end
      end

      def get(*args)
        hit_or_miss = get_from_cache(*args)
        if hit_or_miss.is_a?(Hitnmiss::Driver::Miss)
          return prime(*args)
        elsif hit_or_miss.is_a?(Hitnmiss::Driver::Hit)
          return hit_or_miss.value
        else
          raise UnsupportedDriverResponse.new("Driver '#{self.class.driver.inspect}' did not return an object of the support types (Hitnmiss::Driver::Hit, Hitnmiss::Driver::Miss)")
        end
      end

      def prime(*args)
        cacheable_entity = fetch(*args)
        cache_entity(args, cacheable_entity)
        return cacheable_entity.value
      end

      private

      def get_from_cache(*args)
        Hitnmiss.driver(self.class.driver).get(generate_key(*args))
      end

      def enrich_entity_expiration(unenriched_entity)
        if unenriched_entity.expiration
          return unenriched_entity
        else
          return Hitnmiss::Entity.new(unenriched_entity.value,
                                      self.class.default_expiration,
                                      unenriched_entity.fingerprint)
        end
      end

      def cache_entity(args, cacheable_entity)
        entity = enrich_entity_expiration(cacheable_entity)
        Hitnmiss.driver(self.class.driver).set(generate_key(*args), entity)
      end
    end
  end
end
