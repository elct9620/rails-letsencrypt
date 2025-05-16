# frozen_string_literal: true

module LetsEncrypt
  class Error < StandardError; end

  class MaxCheckExceeded < Error; end
  class InvalidStatus < Error; end
end
