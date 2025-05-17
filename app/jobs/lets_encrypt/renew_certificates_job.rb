# frozen_string_literal: true

module LetsEncrypt
  # :nodoc:
  class RenewCertificatesJob < ApplicationJob
    queue_as :default

    def perform
      service = LetsEncrypt::RenewService.new

      LetsEncrypt.certificate_model.renewable.each do |certificate|
        next if service.execute(certificate)

        certificate.update(renew_after: 1.day.from_now)
      end
    end
  end
end
