require 'hitnmiss/repository/cache_management'

module Hitnmiss
  module Repository
    def self.included(mod)
      mod.include(CacheManagement)
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
      private

      def enrich_entity_expiration(unenriched_entity)
        if unenriched_entity.expiration
          return unenriched_entity
        else
          return Hitnmiss::Entity.new(unenriched_entity.value,
                                      expiration: self.class.default_expiration,
                                      fingerprint: unenriched_entity.fingerprint,
                                      last_modified: unenriched_entity.last_modified)
        end
      end

      def cache_entity(args, cacheable_entity)
        entity = enrich_entity_expiration(cacheable_entity)
        super(args, entity)
      end
    end
  end
end
