require 'openssl'
require 'acme-client'
require 'letsencrypt/engine'
require 'letsencrypt/logger_proxy'

# :nodoc:
module LetsEncrypt
  def self.client
    @client ||= ::Acme::Client.new(private_key: private_key, endpoint: endpoint)
  end

  def self.private_key
    # TODO: Add options to retrieve key
    @private_key ||= if private_key_path.exist?
                       OpenSSL::PKey::RSA.new(File.open(private_key_path))
                     else
                       generate_private_key
                     end
  end

  def self.endpoint
    @endpoint ||= if Rails.env.production?
                    'https://acme-v01.api.letsencrypt.org/'
                  else
                    'https://acme-staging.api.letsencrypt.org'
                  end
  end

  def self.register(email)
    registration = client.register(contact: "mailto:#{email}")
    logger.info "Successfully registered private key with address #{email}"
    registration.agree_terms
    logger.info 'Terms have been accepted'
    true
  end

  def self.private_key_path
    # TODO: Add options for specify path
    Rails.root.join('config', 'letsencrypt.key')
  end

  def self.generate_private_key
    key = OpenSSL::PKey::RSA.new(4096)
    File.open(private_key_path, 'w') { |f| f.write(key.to_s) }
    logger.info "Created new private key for Let's Encrypt"
    key
  end

  def self.logger
    @logger ||= LoggerProxy.new(Rails.logger, tags: ['LetsEncrypt'])
  end
end
