module Hitnmiss
  module Repository
    module Fetcher
      private

      def fetch(*args)
        raise Hitnmiss::Errors::NotImplemented
      end

      def fetch_all(keyspace)
        raise Hitnmiss::Errors::NotImplemented
      end
    end
  end
end
