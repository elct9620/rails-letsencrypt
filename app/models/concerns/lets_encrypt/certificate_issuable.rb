module LetsEncrypt
  # :nodoc:
  module CertificateIssuable
    extend ActiveSupport::Concern

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
      csr = OpenSSL::X509::Request.new
      csr.subject = OpenSSL::X509::Name.new(
        [['CN', domain, OpenSSL::ASN1::UTF8STRING]]
      )
      private_key = OpenSSL::PKey::RSA.new(key)
      csr.public_key = private_key.public_key
      csr.sign(private_key, OpenSSL::Digest::SHA256.new)
      csr
    end

    def create_certificate
      https_cert = LetsEncrypt.client.new_certificate(csr)
      self.certificate = https_cert.to_pem
      self.intermediaries = https_cert.chain_to_pem
      self.expires_at = https_cert.x509.not_after
      self.renew_after = (expires_at - 1.month) + rand(10).days
      save!
    end
  end
end
