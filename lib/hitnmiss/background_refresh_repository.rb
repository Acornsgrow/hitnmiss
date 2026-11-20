require 'hitnmiss/repository/cache_management'
require 'thread'

module Hitnmiss
  module BackgroundRefreshRepository
    class RefreshIntervalRequired < StandardError; end

    def self.included(mod)
      mod.include(OptionalLogger::LoggerManagement)
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

      def stale?(*args, **kwargs)
        true
      end

      def refresh(*args, swallow_exceptions: [], **kwargs)
        logger.debug("hitnmiss: refresh(#{args.inspect}, #{kwargs.inspect}, swallow_exceptions: #{swallow_exceptions.inspect}) called")
        if swallow_exceptions.empty?
          logger.debug("hitnmiss: refresh(#{args.inspect}, #{kwargs.inspect}, swallow_exceptions: #{swallow_exceptions.inspect}) about to check stale?")
          if stale?(*args, **kwargs)
            logger.debug("hitnmiss: refresh(#{args.inspect}, #{kwargs.inspect}, swallow_exceptions: #{swallow_exceptions.inspect}) is stale, about to prime")
            prime(*args, **kwargs)
          end
        else
          begin
            logger.debug("hitnmiss: refresh(#{args.inspect}, #{kwargs.inspect}, swallow_exceptions: #{swallow_exceptions.inspect}) about to check stale?")
            if stale?(*args, **kwargs)
              logger.debug("hitnmiss: refresh(#{args.inspect}, #{kwargs.inspect}, swallow_exceptions: #{swallow_exceptions.inspect}) is stale, about to prime")
              prime(*args, **kwargs)
            end
          rescue *swallow_exceptions => e
            logger.error("hitnmiss: refresh(#{args.inspect}, #{kwargs.inspect}, swallow_exceptions: #{swallow_exceptions.inspect}) swallowed exception: #{e.inspect}")
            logger.error(e.backtrace.join("\n"))
          end
        end
      end

      def background_refresh(*args, swallow_exceptions: [], **kwargs)
        logger.debug("hitnmiss: background_refresh(#{args.inspect}, #{kwargs.inspect}) called")
        @refresh_thread = Thread.new(self, args, kwargs) do |repository, args, kwargs|
          while(true) do
            repository.logger.debug("hitnmiss: background_refresh(#{args.inspect}, #{kwargs.inspect}): about to call refresh()")
            refresh(*args, swallow_exceptions: swallow_exceptions, **kwargs)
            repository.logger.debug("hitnmiss: background_refresh(#{args.inspect}, #{kwargs.inspect}): about to sleep for #{repository.class.refresh_interval}")
            sleep repository.class.refresh_interval
          end
        end
        @refresh_thread.abort_on_exception = true
        logger.debug("hitnmiss: background_refresh(#{args.inspect}, #{kwargs.inspect}) enabled abort on exception")
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
