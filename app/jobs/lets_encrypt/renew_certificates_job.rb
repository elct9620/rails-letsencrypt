# frozen_string_literal: true

module LetsEncrypt
  # :nodoc:
  class RenewCertificatesJob < ApplicationJob
    queue_as :default

    def perform
      service = LetsEncrypt::RenewService.new

      LetsEncrypt.certificate_model.renewable.each do |certificate|
        service.execute(certificate)
      rescue LetsEncrypt::MaxCheckExceeded, LetsEncrypt::InvalidStatus
        certificate.update(renew_after: 1.day.from_now)
      rescue Acme::Client::Error => e
        certificate.update(renew_after: 1.day.from_now)
        Rails.logger.error("LetsEncrypt::RenewCertificatesJob: #{e.message}")
      end
    end
  end
end
