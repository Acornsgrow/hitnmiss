module Hitnmiss
  module Driver
    class Hit
      attr_reader :value

      def initialize(value)
        @value = value
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
