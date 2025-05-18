# frozen_string_literal: true

module AcmeTestHelper
  DIRECTORY_BODY = <<~JSON
    {
            "keyChange": "https://acme-staging-v02.api.letsencrypt.org/acme/key-change",
            "meta": {
              "caaIdentities": [
                "letsencrypt.org"
              ],
              "profiles": {
                "classic": "https://letsencrypt.org/docs/profiles#classic",
                "shortlived": "https://letsencrypt.org/docs/profiles#shortlived (not yet generally available)",
                "tlsserver": "https://letsencrypt.org/docs/profiles#tlsserver"
              },
              "termsOfService": "https://letsencrypt.org/documents/LE-SA-v1.5-February-24-2025.pdf",
              "website": "https://letsencrypt.org/docs/staging-environment/"
            },
            "newAccount": "https://acme-staging-v02.api.letsencrypt.org/acme/new-acct",
            "newNonce": "https://acme-staging-v02.api.letsencrypt.org/acme/new-nonce",
            "newOrder": "https://acme-staging-v02.api.letsencrypt.org/acme/new-order",
            "renewalInfo": "https://acme-staging-v02.api.letsencrypt.org/draft-ietf-acme-ari-03/renewalInfo",
            "revokeCert": "https://acme-staging-v02.api.letsencrypt.org/acme/revoke-cert"
          }
  JSON

  ORDER_BODY = <<~JSON
    {
          "status": "%<status>s",
          "expires": "2016-01-05T14:09:07.99Z",

          "notBefore": "2016-01-01T00:00:00Z",
          "notAfter": "2016-01-08T00:00:00Z",

          "identifiers": [
            { "type": "dns", "value": "%<domain>s" }
          ],

          "authorizations": [
            "https://acme-staging-v02.api.letsencrypt.org/acme/authz/r4HqLzrSrpI"
          ],

          "finalize": "https://acme-staging-v02.api.letsencrypt.org/acme/order/TOlocE8rfgo/finalize"
        }
  JSON

  AUTHZ_BODY = <<~JSON
    {
       "status": "%<status>s",
       "expires": "2016-01-02T14:09:30Z",

       "identifier": {
         "type": "dns",
         "value": "%<domain>s"
       },

       "challenges": [
         {
           "type": "http-01",
           "status": "pending",
           "url": "https://acme-staging-v02.api.letsencrypt.org/acme/chall/prV_B7yEyA4",
           "token": "DGyRejmCefe7v4NfDGDKfA"
         },
         {
           "type": "dns-01",
           "status": "pending",
           "url": "https://acme-staging-v02.api.letsencrypt.org/acme/chall/Rg5dV14Gh1Q",
           "token": "DGyRejmCefe7v4NfDGDKfA"
         }
       ]
     }
  JSON

  ORDER_FINALIZE_BODY = <<~JSON
    {
      "status": "%<status>s",
      "expires": "2016-01-20T14:09:07.99Z",

      "notBefore": "2016-01-01T00:00:00Z",
      "notAfter": "2016-01-08T00:00:00Z",

      "identifiers": [
        { "type": "dns", "value": "%<domain>s" }
      ],

      "authorizations": [
        "https://acme-staging-v02.api.letsencrypt.org/acme/authz/r4HqLzrSrpI"
      ],

      "finalize": "https://acme-staging-v02.api.letsencrypt.org/acme/order/TOlocE8rfgo/finalize",

      "certificate": "https://acme-staging-v02.api.letsencrypt.org/acme/cert/mAt3xBGaobw"
    }
  JSON

  def given_acme_directory
    stub_request(:get, 'https://acme-staging-v02.api.letsencrypt.org/directory')
      .to_return(status: 200, body: DIRECTORY_BODY, headers: {
                   'Content-Type' => 'application/json'
                 })
  end

  def given_acme_nonce(nonce: 'dummy-nonce')
    stub_request(:head, 'https://acme-staging-v02.api.letsencrypt.org/acme/new-nonce')
      .to_return(status: 204, body: '', headers: {
                   'Replay-Nonce' => nonce
                 })
  end

  def given_acme_account
    stub_request(:post, 'https://acme-staging-v02.api.letsencrypt.org/acme/new-acct')
      .to_return(status: 200, body: '{}', headers: {
                   'Content-Type' => 'application/json',
                   'Location' => 'https://acme-staging-v02.api.letsencrypt.org/acme/acct/evOfKhNU60wg'
                 })

    stub_request(:post, 'https://acme-staging-v02.api.letsencrypt.org/acme/acct/evOfKhNU60wg')
      .to_return(status: 200, body: '{}', headers: {
                   'Content-Type' => 'application/json'
                 })
  end

  def given_acme_order(status: 'pending', domain: 'example.com')
    stub_request(:post, 'https://acme-staging-v02.api.letsencrypt.org/acme/new-order')
      .to_return(status: 201, body: format(ORDER_BODY, status:, domain:), headers: {
                   'Location' => 'https://acme-staging-v02.api.letsencrypt.org/acme/order/TOlocE8rfgo',
                   'Content-Type' => 'application/json'
                 })
  end

  def given_acme_authorization(status: 'pending', domain: 'example.com')
    stub_request(:post, 'https://acme-staging-v02.api.letsencrypt.org/acme/authz/r4HqLzrSrpI')
      .to_return(status: 200, body: format(AUTHZ_BODY, status:, domain:), headers: {
                   'Content-Type' => 'application/json'
                 })
  end

  def given_acme_challenge(status: 'pending')
    stub_request(:post, 'https://acme-staging-v02.api.letsencrypt.org/acme/chall/prV_B7yEyA4')
      .to_return(status: 200, body: { status: }.to_json, headers: {
                   'Content-Type' => 'application/json'
                 })
  end

  def given_acme_finalize(status: 'valid', domain: 'example.com')
    stub_request(:post, 'https://acme-staging-v02.api.letsencrypt.org/acme/order/TOlocE8rfgo/finalize')
      .to_return(status: 200, body: format(ORDER_FINALIZE_BODY, status:, domain:), headers: {
                   'Location' => 'https://acme-staging-v02.api.letsencrypt.org/acme/order/TOlocE8rfgo',
                   'Content-Type' => 'application/json'
                 })
  end

  def given_acme_certificate(pem:)
    stub_request(:post, 'https://acme-staging-v02.api.letsencrypt.org/acme/cert/mAt3xBGaobw')
      .to_return(status: 200, body: pem, headers: {
                   'Content-Type' => 'application/pem-certificate-chain'
                 })
  end
end
