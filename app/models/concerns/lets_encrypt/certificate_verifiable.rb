module LetsEncrypt
  # :nodoc:
  module CertificateVerifiable
    extend ActiveSupport::Concern

    def verify
      start_authorize
      start_challenge
      wait_verify_status
      check_verify_status
    rescue Acme::Client::Error => e
      retry_on_verify_error(e)
    end

    private

    def start_authorize
      authorization = LetsEncrypt.client.authorize(domain: domain)
      @challenge = authorization.http01
      self.verification_path = @challenge.filename
      self.verification_string = @challenge.file_content
      save!
    end

    def start_challenge
      logger.info "Attempting verification of #{domain}"
      @challenge.request_verification
    end

    def wait_verify_status
      checks = 0
      until @challenge.verify_status != 'pending'
        checks += 1
        if checks > 30
          logger.info 'Status remained at pending for 30 checks'
          return false
        end
        sleep 1
      end
    end

    def check_verify_status
      unless @challenge.verify_status == 'valid'
        logger.info "Status was not valid (was: #{@challenge.verify_status})"
        return false
      end

      true
    end

    def retry_on_verify_error
      @retries = 0
      if e.is_a?(Acme::Client::Error::BadNonce) && @retries < 5
        @retries += 1
        # rubocop:disable Metrics/LineLength
        logger.info "Bad nounce encountered. Retrying (#{@retries} of 5 attempts)"
        # rubocop:enable Metrics/LineLength
        sleep 1
        verify
      else
        logger.info "Error: #{e.class} (#{e.message})"
        return false
      end
    end
  end
end
