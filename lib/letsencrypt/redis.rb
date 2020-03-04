# frozen_string_literal: true

module LetsEncrypt
  # :nodoc:
  class Redis
    class << self
      def connection
        @connection ||= ::Redis.new(url: LetsEncrypt.config.redis_url)
      end

      # Save certificate into redis.
      def save(cert)
        return unless cert.key.present? && cert.bundle.present?
        LetsEncrypt.logger.info "Save #{cert.domain}'s certificate (bundle) to redis"
        connection.set "#{cert.domain}.key", cert.key
        connection.set "#{cert.domain}.crt", cert.bundle
      end

      # Delete certificate from redis.
      def delete(cert)
        return unless cert.key.present? && cert.certificate.present?
        LetsEncrypt.logger.info "Delete #{cert.domain}'s certificate from redis"
        connection.del "#{cert.domain}.key"
        connection.del "#{cert.domain}.crt"
      end
    end
  end
end
