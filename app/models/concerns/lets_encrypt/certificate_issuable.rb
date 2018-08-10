# frozen_string_literal: true

module LetsEncrypt
  # :nodoc:
  module CertificateIssuable
    extend ActiveSupport::Concern

    # Returns true if issue new certificate succeed.
    def issue
      logger.info "Getting certificate for #{domain}"
      create_certificate
      # rubocop:disable Metrics/LineLength
      logger.info "Certificate issued (expires on #{expires_at}, will renew after #{renew_after})"
      # rubocop:enable Metrics/LineLength
      true
    end

    private

    def csr
      Acme::Client::CertificateRequest.new(
        private_key: OpenSSL::PKey::RSA.new(key),
        subject: {
          common_name: domain
        }
      )
    end

    def create_certificate
      order.finalize(csr: csr)
      sleep 1 while order.status == 'processing'
      fullchain = order.certificate.split("\n\n")
      cert = OpenSSL::X509::Certificate.new(fullchain.shift)
      self.certificate = cert.to_pem
      self.intermediaries = fullchain.join("\n\n")
      self.expires_at = cert.not_after
      self.renew_after = (expires_at - 1.month) + rand(10).days
      save!
    end
  end
end
