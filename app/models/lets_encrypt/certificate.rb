module LetsEncrypt
  # :nodoc:
  class Certificate < ApplicationRecord
    include CertificateVerifiable
    include CertificateIssuable

    validates :domain, presence: true, uniqueness: true

    before_create -> { self.key = OpenSSL::PKey::RSA.new(4096).to_s }

    def get
      verify && issue
    end

    protected

    def logger
      LetsEncrypt.logger
    end
  end
end
