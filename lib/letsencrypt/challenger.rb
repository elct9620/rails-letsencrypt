# frozen_string_literal: true

module LetsEncrypt
  # The ACME challenger to process the challenge
  class Challenger
    MAX_CHECKS = 30

    STATUS_PENDING = 'pending'
    STATUS_VALID = 'valid'

    attr_reader :logger, :max_checks

    def initialize(max_checks: MAX_CHECKS)
      @max_checks = max_checks
    end

    def execute(challenge)
      challenge.request_validation

      wait(challenge)
      assert(challenge)

      true
    end

    private

    def wait(challenge)
      checks = 0

      until challenge.status != STATUS_PENDING
        checks += 1
        if checks > max_checks
          raise LetsEncrypt::MaxCheckExceeded,
                "Status remained at pending for #{max_checks} checks"
        end

        sleep 1
        challenge.reload
      end
    end

    def assert(challenge)
      return if challenge.status == STATUS_VALID

      raise LetsEncrypt::InvalidStatus, "Status not valid (was: #{challenge.status})"
    end
  end
end
