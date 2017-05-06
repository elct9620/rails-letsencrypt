module LetsEncrypt
  # :nodoc:
  class Redis
    class << self
      def connection
        @connection ||= ::Redis.new(url: LetsEncrypt.config.redis_url)
      end

      def save(cert)
        LetsEncrypt.logger.info "Save #{cert.domain}'s certificate to redis"
        connection.set "#{cert.domain}.key", cert.key
        connection.set "#{cert.domain}.crt", cert.certificate
      end
    end
  end
end
