require 'hitnmiss/repository/driver_management'
require 'hitnmiss/repository/fetcher'
require 'hitnmiss/repository/key_generation'
require 'thread'

module Hitnmiss
  module BackgroundRefreshRepository
    class RefreshIntervalRequired < StandardError; end

    def self.included(mod)
      mod.extend(Repository::DriverManagement)
      mod.include(Repository::Fetcher)
      mod.include(Repository::KeyGeneration)
      mod.extend(ClassMethods)
      mod.include(InstanceMethods)
    end

    module ClassMethods
      def refresh_interval(interval_in_seconds=nil)
        if interval_in_seconds
          @refresh_interval = interval_in_seconds
        else
          @refresh_interval
        end
      end
    end

    module InstanceMethods
      # NOTE: exactly the same implementation as Repository
      #
      # I am not sure if this is really the way it should be. Maybe it should
      # somhow trigger the background refresh thread to update and this becomes
      # non-blocking? The problem with that is it becomes to have a guarantee
      # that it has been updated at least once.
      def prime(*args)
        cacheable_entity = fetch(*args)
        cache_entity(args, cacheable_entity)
        return cacheable_entity.value
      end

      # NOTE: exactly the same implementation as Repository
      #
      # I am not sure if this is really the way it should be. Maybe it should
      # somhow trigger the background refresh thread to update and this becomes
      # non-blocking? The problem with that is it becomes to have a guarantee
      # that it has been updated at least once.
      def prime_all
        cacheable_entities = fetch_all(self.class.keyspace)
        return cacheable_entities.map do |cacheable_entity_hash|
          args = cacheable_entity_hash.fetch(:args)
          cacheable_entity = cacheable_entity_hash.fetch(:entity)
          cache_entity(args, cacheable_entity)
          cacheable_entity.value
        end
      end

      # NOTE: exactly the same implementation as Repository
      #
      # I am not sure if we should have the foregrounded prime happen on a miss
      # or if it should raise an exception. My assumption is to let the
      # foregrounded prime happen in case they never pre-primed the cache.
      def get(*args)
        hit_or_miss = get_from_cache(*args)
        if hit_or_miss.is_a?(Hitnmiss::Driver::Miss)
          return prime(*args)
        elsif hit_or_miss.is_a?(Hitnmiss::Driver::Hit)
          return hit_or_miss.value
        else
          raise Hitnmiss::Repository::UnsupportedDriverResponse.new("Driver '#{self.class.driver.inspect}' did not return an object of the support types (Hitnmiss::Driver::Hit, Hitnmiss::Driver::Miss)")
        end
      end

      # NOTE: exactly the same implementation as Repository
      def delete(*args)
        Hitnmiss.driver(self.class.driver).delete(generate_key(*args))
      end

      # NOTE: exactly the same implementation as Repository
      def all
        Hitnmiss.driver(self.class.driver).all(self.class.keyspace)
      end

      # NOTE: exactly the same implementation as Repository
      def clear
        Hitnmiss.driver(self.class.driver).clear(self.class.keyspace)
      end

      def initialize
        if self.class.refresh_interval.nil?
          raise RefreshIntervalRequired, 'the refresh_interval must be set'
        end
      end

      def stale?(*args)
        true
      end

      def refresh(*args)
        if stale?(*args)
          prime(*args)
        end
      end

      def background_refresh(*args)
        @refresh_thread = Thread.new(self, args) do |repository, args|
          while(true) do
            refresh(*args)
            sleep repository.class.refresh_interval
          end
        end
        @refresh_thread.abort_on_exception = true
      end

      private

      def get_from_cache(*args)
        Hitnmiss.driver(self.class.driver).get(generate_key(*args))
      end

      def strip_expiration(unstripped_entity)
        if unstripped_entity.expiration
          return Hitnmiss::Entity.new(unstripped_entity.value,
                                      nil, unstripped_entity.fingerprint)
        else
          return unstripped_entity
        end
      end

      def cache_entity(args, cacheable_entity)
        entity = strip_expiration(cacheable_entity)
        Hitnmiss.driver(self.class.driver).set(generate_key(*args), entity)
      end
    end
  end
end
