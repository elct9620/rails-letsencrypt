# frozen_string_literal: true

module LetsEncrypt
  # Process the verification of the domain
  class VerifyService
    MAX_CHECKS = 30
    MAX_RETRYS = 5

    STATUS_PENDING = 'pending'
    STATUS_VALID = 'valid'

    attr_reader :acme_client, :logger

    def initialize(acme_client: LetsEncrypt.client, logger: LetsEncrypt.logger)
      @acme_client = acme_client
      @logger = logger
    end

    def execute(certificate) # rubocop:disable Metrics/AbcSize
      with_retries do
        order = acme_client.new_order(identifiers: [certificate.domain])
        challenge = order.authorizations.first.http

        certificate.challenge!(challenge.filename, challenge.file_content)
        challenge.request_validation

        wait_and_assert(challenge, certificate.domain)
      end
    rescue Acme::Client::Error => e
      logger.error "#{certificate.domain}: #{e.message}"
    end

    private

    def with_retries
      attempts = 0
      yield
    rescue Acme::Client::Error::BadNonce
      attempts += 1
      if attempts < MAX_RETRYS
        logger.info "#{domain}: Bad nonce encountered. Retrying (#{attempts} of #{MAX_RETRYS} attempts)"
        sleep 1
        retry
      end

      raise
    end

    def wait_and_assert(challenge, domain)
      wait(challenge, domain)
      assert(challenge, domain)
    end

    def wait(challenge, domain)
      checks = 0
      until challenge.status != STATUS_PENDING
        checks += 1
        if checks > MAX_CHECKS
          logger.info "#{domain}: Status remained at pending for 30 checks"
          return
        end
        sleep 1
        challenge.reload
      end
    end

    def assert(challenge, domain)
      unless challenge.status == STATUS_VALID
        logger.info "#{domain}: Status was not valid (was: #{challenge.status})"
        return false
      end

      logger.info "#{domain}: Status was valid"
      true
    end
  end
end
