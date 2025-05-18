# frozen_string_literal: true

module LetsEncrypt
  # The status checker to make a loop until the status is reached
  class StatusChecker
    DEFAULT_MAX_ATTEMPTS = 30
    DEFAULT_INTERVAL = 1

    attr_reader :max_attempts, :interval

    def initialize(max_attempts: DEFAULT_MAX_ATTEMPTS, interval: DEFAULT_INTERVAL)
      @max_attempts = max_attempts
      @interval = interval
    end

    def execute
      attempts = 0

      loop do
        break if yield

        attempts += 1
        raise MaxCheckExceeded, "Max attempts exceeded (#{max_attempts})" if attempts >= max_attempts

        sleep interval
      end
    end
  end
end
