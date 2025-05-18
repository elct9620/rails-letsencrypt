# frozen_string_literal: true

require 'rails_helper'

RSpec.describe LetsEncrypt::RenewCertificatesJob, type: :job do
  let(:certificate) { LetsEncrypt::Certificate.new(domain: 'example.com') }
  let(:pem) do
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
    ActiveJob::Base.queue_adapter = :test

    given_acme_directory
    given_acme_account
    given_acme_nonce
    given_acme_order
    given_acme_authorization
    given_acme_finalize
    given_acme_certificate(pem:)

    allow(LetsEncrypt::Certificate).to receive(:renewable).and_return([certificate])
  end

  describe 'when renew success' do
    before do
      given_acme_challenge
      given_acme_challenge(status: 'valid')

      LetsEncrypt::RenewCertificatesJob.perform_now
    end

    it { expect(certificate.expires_at).to(satisfy { |time| time >= Time.zone.parse('2025-06-17T00:00') }) }
  end

  describe 'renew failed' do
    before do
      given_acme_challenge
      given_acme_challenge(status: 'invalid')

      LetsEncrypt::RenewCertificatesJob.perform_now
    end

    it { expect(certificate.expires_at).to be_nil }
    it { expect(certificate.renew_after).to(satisfy { |time| time > Time.zone.now }) }
  end
end
