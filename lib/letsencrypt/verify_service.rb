# frozen_string_literal: true

module LetsEncrypt
  # Process the verification of the domain
  class VerifyService
    MAX_CHECKS = 30

    STATUS_PENDING = 'pending'
    STATUS_VALID = 'valid'

    attr_reader :logger, :checker

    def initialize(logger: LetsEncrypt.logger, max_checks: MAX_CHECKS)
      @logger = logger
      @checker = StatusChecker.new(max_attempts: max_checks)
    end

    def execute(certificate, order)
      with_retries do
        challenge = order.authorizations.first.http

        certificate.challenge!(challenge.filename, challenge.file_content)

        challenge.request_validation

        checker.execute do
          challenge.reload
          challenge.status != STATUS_PENDING
        end
        assert(challenge)
      end
    end

    private

    def assert(challenge)
      return if challenge.status == STATUS_VALID

      raise LetsEncrypt::InvalidStatus, "Status not valid (was: #{challenge.status})"
    end
  end
end
