# frozen_string_literal: true

module LetsEncrypt
  # The status checker to make a loop until the status is reached
  class StatusChecker
    attr_reader :max_attempts, :interval

    def initialize(max_attempts:, interval:)
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
