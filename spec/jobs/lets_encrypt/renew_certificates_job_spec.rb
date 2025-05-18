# frozen_string_literal: true

require 'rails_helper'

RSpec.describe LetsEncrypt::RenewCertificatesJob, type: :job do
  let(:certificate) { LetsEncrypt::Certificate.new(domain: 'example.com') }

  before do
    ActiveJob::Base.queue_adapter = :test

    allow(LetsEncrypt::Certificate).to receive(:renewable).and_return([certificate])
  end

  let(:acme_directory) do
    <<~JSON
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
  end

  let(:acme_order) do
    <<~JSON
       {
        "status": "pending",
        "expires": "2016-01-05T14:09:07.99Z",

        "notBefore": "2016-01-01T00:00:00Z",
        "notAfter": "2016-01-08T00:00:00Z",

        "identifiers": [
          { "type": "dns", "value": "example.org" }
        ],

        "authorizations": [
          "https://acme-staging-v02.api.letsencrypt.org/acme/authz/r4HqLzrSrpI"
        ],

        "finalize": "https://acme-staging-v02.api.letsencrypt.org/acme/order/TOlocE8rfgo/finalize"
      }
    JSON
  end

  let(:acme_authz) do
    <<~JSON
      {
         "status": "pending",
         "expires": "2016-01-02T14:09:30Z",

         "identifier": {
           "type": "dns",
           "value": "example.org"
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
  end

  let(:acme_finalize) do
    <<~JSON
       {
        "status": "valid",
        "expires": "2016-01-20T14:09:07.99Z",

        "notBefore": "2016-01-01T00:00:00Z",
        "notAfter": "2016-01-08T00:00:00Z",

        "identifiers": [
          { "type": "dns", "value": "www.example.org" },
          { "type": "dns", "value": "example.org" }
        ],

        "authorizations": [
          "https://acme-staging-v02.api.letsencrypt.org/acme/authz/PAniVnsZcis",
          "https://acme-staging-v02.api.letsencrypt.org/acme/authz/r4HqLzrSrpI"
        ],

        "finalize": "https://acme-staging-v02.api.letsencrypt.org/acme/order/TOlocE8rfgo/finalize",

        "certificate": "https://acme-staging-v02.api.letsencrypt.org/acme/cert/mAt3xBGaobw"
      }
    JSON
  end

  let(:acme_pem) do
    <<~PEM
      -----BEGIN CERTIFICATE-----
      MIICjzCCAXcCAQAwDQYJKoZIhvcNAQELBQAwADAeFw0yNTA1MTgwODMyMDRaFw0y
      NTA2MTcwODMyMTNaMBsxGTAXBgNVBAMMEGV4YW1wbGUuY29tL0M9RUUwggEiMA0G
      CSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQCqOFgqYlK8OUfmcL1zLOAWOY69zPQS
      Cst+bXUjL/Lf7pz25bFraQZ7sbFgkEqsJ4N6VmdkeSYABCfSaGMsD3WygCeONdek
      Z7r0GPJ/nN9GGoJt576PqSc5nIj3odYfIWY0Rg5ZxAzYkbZL4PBfX2nzR0DHmuiB
      4xAawCy/1gUZcdJdVuLKcm88c7ptZuvDWtk3k++tawsayz+Su6pyZb7Ib9Bnt4Jx
      ZZBJwRqYQF7L+PCmXydR+Te7XI0KjaIonqnvOh4lEq8HH41QZz8ptqYK2wZgRrB9
      3AZAYv9FS+qWx5Sdn98OhX68lJwYXCx195jDfJZyNS6G4m+bsJGtNxLrAgMBAAEw
      DQYJKoZIhvcNAQELBQADggEBAFlDgb8vDPaCvmA2sRY3QvmJZh8jPFX1nANmNrWr
      ZgMFXP2EmrPqpgW7k3LlZ3pcYg5CruRH4+oTnCeHfryda1Ko8z8MS9Zslrz7CmaW
      7GExw2jH3Ns4OXAwak03uiW9vRxGxcfRoqluFH/yO6lx6a8Hy4ZS++BlWju3SwJ1
      kD/e8Tv917jhm9BJZvLkLOwwXI3CWSVZdctwVl7PtNrMaFlZaMqa7SwbF2lbjuZQ
      Svg/K5bzrZmhA6YDFLQs4HOcshK0pmpoj4TtLlulgnVv2BLjXDlpGdbK5KtXc4qg
      +vsUzgp55BU0Um2XKQPL+VtR9s58lrX2UiUKD3+nWzp0Fpg=
      -----END CERTIFICATE-----
    PEM
  end

  before do
    stub_request(:get, 'https://acme-staging-v02.api.letsencrypt.org/directory')
      .to_return(status: 200, body: acme_directory, headers: {
                   'Content-Type' => 'application/json'
                 })

    stub_request(:head, 'https://acme-staging-v02.api.letsencrypt.org/acme/new-nonce')
      .to_return(status: 204, body: '', headers: {
                   'Replay-Nonce' => 'nonce'
                 })

    stub_request(:post, 'https://acme-staging-v02.api.letsencrypt.org/acme/new-acct')
      .to_return(status: 200, body: '{}', headers: {
                   'Content-Type' => 'application/json',
                   'Location' => 'https://acme-staging-v02.api.letsencrypt.org/acme/acct/evOfKhNU60wg'
                 })

    stub_request(:post, 'https://acme-staging-v02.api.letsencrypt.org/acme/acct/evOfKhNU60wg')
      .to_return(status: 200, body: '{}', headers: {
                   'Content-Type' => 'application/json'
                 })

    stub_request(:post, 'https://acme-staging-v02.api.letsencrypt.org/acme/new-order')
      .to_return(status: 201, body: acme_order, headers: {
                   'Location' => 'https://acme-staging-v02.api.letsencrypt.org/acme/order/TOlocE8rfgo',
                   'Content-Type' => 'application/json'
                 })

    stub_request(:post, 'https://acme-staging-v02.api.letsencrypt.org/acme/authz/r4HqLzrSrpI')
      .to_return(status: 200, body: acme_authz, headers: {
                   'Content-Type' => 'application/json'
                 })

    stub_request(:post, 'https://acme-staging-v02.api.letsencrypt.org/acme/order/TOlocE8rfgo/finalize')
      .to_return(status: 200, body: acme_finalize, headers: {
                   'Location' => 'https://acme-staging-v02.api.letsencrypt.org/acme/order/TOlocE8rfgo',
                   'Content-Type' => 'application/json'
                 })

    stub_request(:post, 'https://acme-staging-v02.api.letsencrypt.org/acme/cert/mAt3xBGaobw')
      .to_return(status: 200, body: acme_pem, headers: {
                   'Content-Type' => 'application/pem-certificate-chain'
                 })
  end

  describe 'when renew success' do
    before do
      stub_request(:post, 'https://acme-staging-v02.api.letsencrypt.org/acme/chall/prV_B7yEyA4')
        .to_return(status: 200, body: '{ "status": "valid" }', headers: {
                     'Content-Type' => 'application/json'
                   })

      LetsEncrypt::RenewCertificatesJob.perform_now
    end

    it { expect(certificate.expires_at).to(satisfy { |time| time >= Time.zone.parse('2025-06-17T00:00') }) }
  end

  describe 'renew failed' do
    before do
      stub_request(:post, 'https://acme-staging-v02.api.letsencrypt.org/acme/chall/prV_B7yEyA4')
        .to_return(status: 200, body: '{ "status": "invalid" }', headers: {})

      LetsEncrypt::RenewCertificatesJob.perform_now
    end

    it { expect(certificate.expires_at).to be_nil }
    it { expect(certificate.renew_after).to(satisfy { |time| time > Time.zone.now }) }
  end
end
