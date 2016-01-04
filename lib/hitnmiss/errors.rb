module Hitnmiss
  module Errors
    class Error < StandardError; end

    class NotImplemented < Error; end

    class UnregisterdDriver < Error; end
  end
end
