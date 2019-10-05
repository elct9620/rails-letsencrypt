# frozen_string_literal: true

namespace :letsencrypt do
  desc 'Renew the certificates will epxired'
  task renew: :environment do
    count = 0
    failed = 0
    LetsEncrypt.config.certificate_model.constantize.renewable do |certificate|
      count += 1
      next if certificate.renew
      failed += 1
      log "Could not renew domain: #{certificate.domain}"
    end

    puts "Total #{count} domains should renew, and #{failed} domains cannot be renewed."
  end
end
