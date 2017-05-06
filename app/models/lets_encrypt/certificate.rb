module LetsEncrypt
  # :nodoc:
  class Certificate < ApplicationRecord
    include CertificateVerifiable
    include CertificateIssuable

    validates :domain, presence: true, uniqueness: true

    before_create -> { self.key = OpenSSL::PKey::RSA.new(4096).to_s }
    after_save -> { save_to_redis }, if: -> { LetsEncrypt.config.use_redis? }

    def get
      verify && issue
    end

    def bundle
      [intermediaries, certificate].join("\n")
    end

    def save_to_redis
      LetsEncrypt::Redis.save(self)
    end

    protected

    def logger
      LetsEncrypt.logger
    end
  end
end
