# frozen_string_literal: true

module LetsEncrypt
  # Process the verification of the domain
  class VerifyService
    attr_reader :logger, :challenger

    def initialize(logger: LetsEncrypt.logger)
      @logger = logger
      @challenger = Challenger.new
    end

    def execute(certificate, order)
      with_retries do
        challenge = order.authorizations.first.http

        certificate.challenge!(challenge.filename, challenge.file_content)

        challenger.execute(challenge)
      end
    end
  end
end
