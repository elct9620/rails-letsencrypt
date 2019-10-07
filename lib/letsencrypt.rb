# frozen_string_literal: true

require 'openssl'
require 'acme-client'
require 'redis'
require 'letsencrypt/railtie'
require 'letsencrypt/engine'
require 'letsencrypt/configuration'
require 'letsencrypt/logger_proxy'
require 'letsencrypt/redis'

# :nodoc:
module LetsEncrypt
  # Production mode API Endpoint
  ENDPOINT = 'https://acme-v02.api.letsencrypt.org/directory'

  # Staging mode API Endpoint, the rate limit is higher
  # but got invalid certificate for testing
  ENDPOINT_STAGING = 'https://acme-staging-v02.api.letsencrypt.org/directory'

  class << self
    # Create the ACME Client to Let's Encrypt
    def client
      @client ||= ::Acme::Client.new(
        private_key: private_key,
        directory: directory
      )
    end

    def private_key
      @private_key ||= OpenSSL::PKey::RSA.new(load_private_key)
    end

    def load_private_key
      return ENV['LETSENCRYPT_PRIVATE_KEY'] if config.use_env_key
      return File.open(private_key_path) if File.exist?(private_key_path)
      generate_private_key
    end

    # Get current using Let's Encrypt endpoint
    def directory
      @endpoint ||= config.use_staging? ? ENDPOINT_STAGING : ENDPOINT
    end

    # Register a Let's Encrypt account
    #
    # This is required a private key to do this,
    # and Let's Encrypt will use this private key to
    # connect with domain and assign the owner who can
    # renew and revoked.
    def register(email)
      account = client.new_account(contact: "mailto:#{email}", terms_of_service_agreed: true)
      logger.info "Successfully registered private key with address #{email}"
      account.kid # TODO: Save KID
      true
    end

    def private_key_path
      config.private_key_path || Rails.root.join('config', 'letsencrypt.key')
    end

    def generate_private_key
      key = OpenSSL::PKey::RSA.new(4096)
      File.open(private_key_path, 'w') { |f| f.write(key.to_s) }
      logger.info "Created new private key for Let's Encrypt"
      key
    end

    def logger
      @logger ||= LoggerProxy.new(Rails.logger, tags: ['LetsEncrypt'])
    end

    # Config how to Let's Encrypt works for Rails
    #
    #  LetsEncrypt.config do |config|
    #    # Always use production mode to connect Let's Encrypt API server
    #    config.use_staging = false
    #   end
    def config(&block)
      @config ||= Configuration.new
      instance_exec(@config, &block) if block_given?
      @config
    end

    # @api private
    def table_name_prefix
      'letsencrypt_'
    end

    def certificate_model
      @certificate_model ||= config.certificate_model.constantize
    end
  end
end
