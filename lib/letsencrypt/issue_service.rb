# frozen_string_literal: true

module LetsEncrypt
  # The issue service to download the certificate
  class IssueService
    attr_reader :checker

    STATUS_PROCESSING = 'processing'

    def initialize(config: LetsEncrypt.config)
      @checker = StatusChecker.new(
        max_attempts: config.max_attempts,
        interval: config.retry_interval
      )
    end

    def execute(certificate, order)
      ActiveSupport::Notifications.instrument('letsencrypt.issue', domain: certificate.domain) do
        issue(certificate, order)
      end
    end

    private

    def issue(certificate, order)
      csr = build_csr(certificate)
      order.finalize(csr:)
      checker.execute do
        order.reload
        order.status != STATUS_PROCESSING
      end
      fullchain = order.certificate.split("\n\n")
      cert = OpenSSL::X509::Certificate.new(fullchain.shift)
      certificate.refresh!(cert, fullchain)
    end

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
