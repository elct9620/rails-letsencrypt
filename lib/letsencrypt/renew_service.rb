# frozen_string_literal: true

module LetsEncrypt
  # The renew service to create or renew the certificate
  class RenewService
    attr_reader :acme_client

    def initialize(acme_client: LetsEncrypt.client)
      @acme_client = acme_client
    end

    def execute(certificate)
      ActiveSupport::Notifications.instrument('letsencrypt.issue', domain: certificate.domain) do
        order = acme_client.new_order(identifiers: [certificate.domain])

        verify_service = VerifyService.new
        return false unless verify_service.execute(certificate, order)

        issue_service = IssueService.new
        issue_service.execute(certificate, order)
      end
    end
  end
end
