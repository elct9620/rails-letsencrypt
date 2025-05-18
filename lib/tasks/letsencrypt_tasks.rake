# frozen_string_literal: true

namespace :letsencrypt do
  desc 'Renew certificates that already expired or expiring soon'
  task renew: :environment do
    success = 0
    failed = 0

    service = LetsEncrypt::RenewService.new

    LetsEncrypt.certificate_model.renewable.each do |certificate|
      service.execute(certificate)
      success += 1
    rescue Acme::Client::Error, LetsEncrypt::MaxCheckExceeded, LetsEncrypt::InvalidStatus => e
      failed += 1
      puts "Could not renew domain: #{certificate.domain} - #{e.message}"
    end

    puts "Renewed #{success} certificates successfully."
    puts "Failed to renew #{failed} certificates."
    puts "Total: #{success + failed} certificates."
  end
end
