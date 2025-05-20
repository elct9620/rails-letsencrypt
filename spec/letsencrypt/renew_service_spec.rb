# frozen_string_literal: true

RSpec.describe LetsEncrypt::RenewService do
  subject(:renew) { service.execute(certificate) }

  let(:service) { described_class.new }
  let(:certificate) { LetsEncrypt::Certificate.create!(domain: 'example.com') }
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
  let(:output) { StringIO.new }

  before do
    LetsEncrypt.config do |config|
      config.retry_interval = 0
    end

    given_acme_directory
    given_acme_account
    given_acme_nonce
    given_acme_order
    given_acme_authorization
    given_acme_challenge(status: 'valid')
    given_acme_finalize(status: 'ready')
    given_acme_certificate(pem:)
  end

  context 'when renew subscribed' do
    before do
      ActiveSupport::Notifications.subscribe('letsencrypt.renew') do |_, _, _, _, payload|
        output.puts "#{payload[:domain]} is renewed"
      end
    end

    it { expect { renew }.to change(output, :string).to include('example.com is renewed') }
  end

  context 'when verify subscribed' do
    before do
      ActiveSupport::Notifications.subscribe('letsencrypt.verify') do |_, _, _, _, payload|
        output.puts "#{payload[:domain]} is verified"
      end
    end

    it { expect { renew }.to change(output, :string).to include('example.com is verified') }
  end

  context 'when issue subscribed' do
    before do
      ActiveSupport::Notifications.subscribe('letsencrypt.issue') do |_, _, _, _, payload|
        output.puts "#{payload[:domain]} is issued"
      end
    end

    it { expect { renew }.to change(output, :string).to include('example.com is issued') }
  end
end
