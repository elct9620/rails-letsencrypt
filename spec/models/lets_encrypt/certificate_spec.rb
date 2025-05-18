# frozen_string_literal: true

require 'rails_helper'

RSpec.describe LetsEncrypt::Certificate do
  subject(:cert) { LetsEncrypt::Certificate.new(domain: 'example.com') }

  let(:key) { OpenSSL::PKey::RSA.new(4096) }
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
    LetsEncrypt.config.save_to_redis = false

    given_acme_directory
    given_acme_account
    given_acme_nonce
    given_acme_order
    given_acme_authorization
    given_acme_challenge(status: 'valid')
    given_acme_finalize
    given_acme_certificate(pem:)
  end

  describe '#active?' do
    before { cert.certificate = pem }

    it { is_expected.to be_active }
  end

  describe '#exipred?' do
    before { cert.expires_at = 3.days.ago }

    it { is_expected.to be_expired }
  end

  describe '#get' do
    subject { cert.get }

    it { is_expected.to be_truthy }
  end

  describe '#save_to_redis' do
    subject(:cert) { LetsEncrypt::Certificate.new(domain: 'example.com') }

    before do
      allow(LetsEncrypt::Redis).to receive(:save)
      LetsEncrypt.config.save_to_redis = true

      cert.save
    end

    it { expect(LetsEncrypt::Redis).not_to have_received(:save) }

    describe 'when certificate is present' do
      subject(:cert) do
        LetsEncrypt::Certificate.new(
          domain: 'example.com',
          certificate: pem,
          key:
        )
      end

      it { expect(LetsEncrypt::Redis).to have_received(:save) }
    end
  end

  describe '#delete_from_redis' do
    subject(:cert) { LetsEncrypt::Certificate.new(domain: 'example.com') }

    before do
      allow(LetsEncrypt::Redis).to receive(:delete)
      LetsEncrypt.config.save_to_redis = true

      cert.destroy
    end

    it { expect(LetsEncrypt::Redis).not_to have_received(:delete) }

    describe 'when certificate is present' do
      subject(:cert) do
        LetsEncrypt::Certificate.new(
          domain: 'example.com',
          certificate: pem,
          key:
        )
      end

      it { expect(LetsEncrypt::Redis).to have_received(:delete) }
    end
  end

  describe '#verify' do
    subject(:cert) { LetsEncrypt::Certificate.new(domain: 'example.com') }

    describe 'when status is valid' do
      it { is_expected.to have_attributes(verify: true) }
    end

    describe 'when status is pending to valid' do
      before do
        given_acme_challenge(status: %w[pending valid])
      end

      it { is_expected.to have_attributes(verify: true) }
    end

    describe 'when Acme::Client::Error is raised' do
      xit { is_expected.to have_attributes(verify: true) }
    end
  end

  describe '#issue' do
    subject(:cert) { LetsEncrypt::Certificate.new(domain: 'example.com', key:) }

    it { is_expected.to have_attributes(issue: true) }
  end
end
