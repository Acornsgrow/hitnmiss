module Hitnmiss
  module Errors
    class Error < StandardError; end

    class NotImplemented < Error; end

    class UnregisteredDriver < Error; end
  end
end
