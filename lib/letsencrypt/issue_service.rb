# frozen_string_literal: true

module LetsEncrypt
  # The issue service to download the certificate
  class IssueService
    attr_reader :logger, :max_checks

    MAX_CHECKS = 30
    STATUS_PROCESSING = 'processing'

    def initialize(logger: LetsEncrypt.logger, max_checks: MAX_CHECKS)
      @logger = logger
      @max_checks = max_checks
    end

    def execute(certificate, order)
      csr = build_csr(certificate)
      logger.info "Getting certificate for #{certificate.domain}"
      order.finalize(csr:)
      wait(order)
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

    def wait(order)
      checks = 0

      until order.status != STATUS_PROCESSING
        checks += 1
        if checks > max_checks
          raise LetsEncrypt::MaxCheckExceeded,
                "Status remained at processing for #{LetsEncrypt::Challenger::MAX_CHECKS} checks"
        end

        sleep 1
        order.reload
      end
    end
  end
end
