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
  ENDPOINT = 'https://acme-v01.api.letsencrypt.org/'
  ENDPOINT_STAGING = 'https://acme-staging.api.letsencrypt.org'

  class << self
    def client
      @client ||= ::Acme::Client.new(
        private_key: private_key,
        endpoint: endpoint
      )
    end

    def private_key
      @private_key ||= OpenSSL::PKey::RSA.new(load_private_key)
    end

    def load_private_key
      return ENV['LETSENCRYPT_PRIVATE_KEY'] if config.use_env_key
      return File.open(private_key_path) if private_key_path.exist?
      generate_private_key
    end

    def endpoint
      @endpoint ||= config.use_staging? ? ENDPOINT_STAGING : ENDPOINT
    end

    def register(email)
      registration = client.register(contact: "mailto:#{email}")
      logger.info "Successfully registered private key with address #{email}"
      registration.agree_terms
      logger.info 'Terms have been accepted'
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

    def config(&block)
      @config ||= Configuration.new
      instance_exec(@config, &block) if block_given?
      @config
    end

    # @api private
    def table_name_prefix
      'letsencrypt_'
    end
  end
end
