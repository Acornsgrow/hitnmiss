module Hitnmiss
  module Driver
    class Hit
      attr_reader :value, :updated_at, :fingerprint

      def initialize(value, updated_at: nil, fingerprint: nil)
        @value = value
        @updated_at = updated_at
        @fingerprint = fingerprint
      end
    end

    class Miss; end

    module Interface
      def set(key, value, expiration_in_seconds)
        raise Hitnmiss::Errors::NotImplemented
      end

      def setnoexp(key, value)
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
