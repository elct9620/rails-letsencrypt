# frozen_string_literal: true

module LetsEncrypt
  # Process the verification of the domain
  class VerifyService
    MAX_RETRYS = 5

    attr_reader :acme_client, :logger, :challenger

    def initialize(acme_client: LetsEncrypt.client, logger: LetsEncrypt.logger)
      @acme_client = acme_client
      @logger = logger
      @challenger = Challenger.new
    end

    def execute(certificate)
      order = acme_client.new_order(identifiers: [certificate.domain])

      with_retries do
        challenge = order.authorizations.first.http

        certificate.challenge!(challenge.filename, challenge.file_content)

        challenger.execute(challenge)
      end
    rescue Acme::Client::Error, LetsEncrypt::MaxCheckExceeded, LetsEncrypt::InvalidStatus => e
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
  end
end
