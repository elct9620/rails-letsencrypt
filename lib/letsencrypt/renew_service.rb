# frozen_string_literal: true

module LetsEncrypt
  # The renew service to create or renew the certificate
  class RenewService
    attr_reader :acme_client, :config

    def initialize(acme_client: LetsEncrypt.client, config: LetsEncrypt.config)
      @acme_client = acme_client
      @config = config
    end

    def execute(certificate)
      ActiveSupport::Notifications.instrument('letsencrypt.renew', domain: certificate.domain) do
        order = acme_client.new_order(identifiers: [certificate.domain])

        verify_service = VerifyService.new(config:)
        verify_service.execute(certificate, order)

        issue_service = IssueService.new(config:)
        issue_service.execute(certificate, order)
      end
    end
  end
end
