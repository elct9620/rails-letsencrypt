# frozen_string_literal: true

module LetsEncrypt
  # Process the verification of the domain
  class VerifyService
    STATUS_PENDING = 'pending'
    STATUS_VALID = 'valid'

    attr_reader :checker

    def initialize(config: LetsEncrypt.config)
      @checker = StatusChecker.new(max_attempts: config.max_attempts)
    end

    def execute(certificate, order)
      challenge = order.authorizations.first.http

      certificate.challenge!(challenge.filename, challenge.file_content)

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
