require 'hitnmiss/repository/cache_management'
require 'thread'

module Hitnmiss
  module BackgroundRefreshRepository
    class RefreshIntervalRequired < StandardError; end

    def self.included(mod)
      mod.include(Repository::CacheManagement)
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

      def strip_expiration(unstripped_entity)
        if unstripped_entity.expiration
          return Hitnmiss::Entity.new(unstripped_entity.value,
                                      fingerprint: unstripped_entity.fingerprint,
                                      last_modified: unstripped_entity.last_modified)
        else
          return unstripped_entity
        end
      end

      def cache_entity(args, cacheable_entity)
        entity = strip_expiration(cacheable_entity)
        super(args, entity)
      end
    end
  end
end
