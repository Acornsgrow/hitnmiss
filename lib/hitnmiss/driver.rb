module Hitnmiss
  module Driver
    class Hit
      attr_reader :value, :updated_at, :fingerprint, :last_modified

      def initialize(value, updated_at: nil, fingerprint: nil,
                     last_modified: nil)
        @value = value
        @updated_at = updated_at
        @fingerprint = fingerprint
        @last_modified = last_modified
      end
    end

    class Miss; end

    module Interface
      def set(key, entity)
        raise Hitnmiss::Errors::NotImplemented
      end

      def get(key)
        raise Hitnmiss::Errors::NotImplemented
      end

      def all(keyspace)
        raise Hitnmiss::Errors::NotImplemented
      end

      def delete(key)
        raise Hitnmiss::Errors::NotImplemented
      end

      def clear(keyspace)
        raise Hitnmiss::Errors::NotImplemented
      end
    end
  end
end
