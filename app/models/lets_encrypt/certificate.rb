# frozen_string_literal: true

module LetsEncrypt
  # == Schema Information
  #
  # Table name: letsencrypt_certificates
  #
  #  id                  :integer          not null, primary key
  #  domain              :string(255)
  #  certificate         :text(65535)
  #  intermediaries      :text(65535)
  #  key                 :text(65535)
  #  expires_at          :datetime
  #  renew_after         :datetime
  #  verification_path   :string(255)
  #  verification_string :string(255)
  #  created_at          :datetime         not null
  #  updated_at          :datetime         not null
  #
  # Indexes
  #
  #  index_letsencrypt_certificates_on_domain       (domain)
  #  index_letsencrypt_certificates_on_renew_after  (renew_after)
  #
  class Certificate < ApplicationRecord
    self.table_name = 'letsencrypt_certificates'

    validates :domain, presence: true, uniqueness: true

    scope :active, -> { where('certificate IS NOT NULL AND expires_at > ?', Time.zone.now) }
    scope :renewable, -> { where('renew_after IS NULL OR renew_after <= ?', Time.zone.now) }
    scope :expired, -> { where(expires_at: ..Time.zone.now) }

    before_create -> { self.key = OpenSSL::PKey::RSA.new(4096).to_s }
    after_destroy -> { delete_from_redis }, if: -> { LetsEncrypt.config.use_redis? && active? }
    after_save -> { save_to_redis }, if: -> { LetsEncrypt.config.use_redis? && active? }

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

    # Returns full-chain bundled certificates
    def bundle
      (certificate || '') + (intermediaries || '')
    end

    def certificate_object
      @certificate_object ||= OpenSSL::X509::Certificate.new(certificate)
    end

    def key_object
      @key_object ||= OpenSSL::PKey::RSA.new(key)
    end

    def challenge!(filename, file_content)
      update!(
        verification_path: filename,
        verification_string: file_content
      )
    end

    def refresh!(cert, fullchain)
      update!(
        certificate: cert.to_pem,
        intermediaries: fullchain.join("\n\n"),
        expires_at: cert.not_after,
        renew_after: (cert.not_after - 1.month) + rand(10).days
      )
    end

    # Save certificate into redis
    def save_to_redis
      LetsEncrypt::Redis.save(self)
    end

    # Delete certificate from redis
    def delete_from_redis
      LetsEncrypt::Redis.delete(self)
    end

    # Returns true if success get a new certificate
    def get
      service = LetsEncrypt::RenewService.new
      service.execute(self)

      true
    rescue Acme::Client::Error, LetsEncrypt::MaxCheckExceeded, LetsEncrypt::InvalidStatus => e
      logger.error "#{domain}: #{e.message}"
      false
    end

    alias renew get

    def verify
      service = LetsEncrypt::VerifyService.new
      service.execute(self, order)

      true
    rescue Acme::Client::Error, LetsEncrypt::MaxCheckExceeded, LetsEncrypt::InvalidStatus => e
      logger.error "#{domain}: #{e.message}"
      false
    end

    def issue
      service = LetsEncrypt::IssueService.new
      service.execute(self, order)

      true
    rescue Acme::Client::Error, LetsEncrypt::MaxCheckExceeded, LetsEncrypt::InvalidStatus => e
      logger.error "#{domain}: #{e.message}"
      false
    end

    protected

    def order
      @order ||= LetsEncrypt.client.new_order(identifiers: [domain])
    end
  end
end
