# frozen_string_literal: true

namespace :letsencrypt do
  desc 'Renew certificates that already expired or expiring soon'
  task renew: :environment do
    count = 0
    failed = 0

    LetsEncrypt.certificate_model.renewable.each do |certificate|
      count += 1

      next if certificate.renew

      failed += 1
      puts "Could not renew domain: #{certificate.domain}"
    end

    puts "Renewed #{count - failed} out of #{count} domains"
  end
end
