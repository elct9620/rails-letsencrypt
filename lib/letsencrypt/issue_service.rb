# frozen_string_literal: true

module LetsEncrypt
  # The issue service to download the certificate
  class IssueService
    attr_reader :logger, :checker

    MAX_CHECKS = 30
    STATUS_PROCESSING = 'processing'

    def initialize(logger: LetsEncrypt.logger, max_checks: MAX_CHECKS)
      @logger = logger
      @checker = StatusChecker.new(max_attempts: max_checks)
    end

    def execute(certificate, order) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      csr = build_csr(certificate)
      logger.info "Getting certificate for #{certificate.domain}"
      order.finalize(csr:)
      checker.execute do
        order.reload
        order.status != STATUS_PROCESSING
      end
      fullchain = order.certificate.split("\n\n")
      cert = OpenSSL::X509::Certificate.new(fullchain.shift)
      certificate.refresh!(cert, fullchain)
      logger.info "Certificate issued for #{certificate.domain} " \
                  "(expires on #{certificate.expires_at}, will renew after #{certificate.renew_after})"
    end

    private

    def build_csr(certificate)
      Acme::Client::CertificateRequest.new(
        private_key: OpenSSL::PKey::RSA.new(certificate.key),
        subject: {
          common_name: certificate.domain
        }
      )
    end
  end
end
