# frozen_string_literal: true

module LetsEncrypt
  # :nodoc:
  class RenewCertificatesJob < ApplicationJob
    queue_as :default

    def perform
      service = LetsEncrypt::RenewService.new

      LetsEncrypt.certificate_model.renewable.each do |certificate|
        service.execute(certificate)
      rescue Acme::Client::Error, LetsEncrypt::MaxCheckExceeded, LetsEncrypt::InvalidStatus
        certificate.update(renew_after: 1.day.from_now)
      end
    end
  end
end
