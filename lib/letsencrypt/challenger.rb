# frozen_string_literal: true

module LetsEncrypt
  # The ACME challenger to process the challenge
  class Challenger
    MAX_CHECKS = 30

    STATUS_PENDING = 'pending'
    STATUS_VALID = 'valid'

    attr_reader :logger, :checker

    def initialize(max_checks: MAX_CHECKS)
      @max_checks = max_checks
      @checker = StatusChecker.new(max_attempts: max_checks)
    end

    def execute(challenge)
      challenge.request_validation

      checker.execute do
        challenge.reload
        challenge.status != STATUS_PENDING
      end
      assert(challenge)
    end

    private

    def assert(challenge)
      return if challenge.status == STATUS_VALID

      raise LetsEncrypt::InvalidStatus, "Status not valid (was: #{challenge.status})"
    end
  end
end
