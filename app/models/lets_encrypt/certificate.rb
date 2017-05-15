# frozen_string_literal: true

module LetsEncrypt
  # :nodoc:
  class Certificate < ActiveRecord::Base
    include CertificateVerifiable
    include CertificateIssuable

    validates :domain, presence: true, uniqueness: true

    scope :active, -> { where('certificate IS NOT NULL AND expires_at > ?', Time.zone.now) }
    scope :renewable, -> { where('renew_after IS NULL OR renew_after <= ?', Time.zone.now) }
    scope :expired, -> { where('expires_at <= ?', Time.zone.now) }

    before_create -> { self.key = OpenSSL::PKey::RSA.new(4096).to_s }
    after_save -> { save_to_redis }, if: -> { LetsEncrypt.config.use_redis? }

    # Returns false if certificate is not issued.
    #
    # This method didn't check certificate is valid,
    # its only uses for checking is there has a certificate.
    def active?
      certificate.present?
    end

    # Returns true if certificate is expired.
    def expired?
      Time.zone.now >= expires_at
    end

    # Returns true if success get a new certificate
    def get
      verify && issue
    end

    alias renew get

    # Returns full-chain bundled certificates
    def bundle
      [intermediaries, certificate].join("\n")
    end

    def certificate_object
      @certificate_object ||= OpenSSL::X509::Certificate.new(certificate)
    end

    def key_object
      @key_object ||= OpenSSL::PKey::RSA.new(key)
    end

    # Save certificate into redis
    def save_to_redis
      LetsEncrypt::Redis.save(self)
    end

    protected

    def logger
      LetsEncrypt.logger
    end
  end
end
