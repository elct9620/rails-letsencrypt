# frozen_string_literal: true

require 'rails_helper'

RSpec.describe LetsEncrypt::Certificate do
  subject(:cert) { LetsEncrypt::Certificate.new }

  let(:intermediaries) { Array.new(3).map { OpenSSL::X509::Certificate.new } }
  let(:key) { OpenSSL::PKey::RSA.new(4096) }
  let(:mock_cert) { OpenSSL::X509::Certificate.new }

  before do
    LetsEncrypt.config.save_to_redis = false

    mock_cert.public_key = key.public_key
    mock_cert.sign(key, OpenSSL::Digest.new('SHA256'))
  end

  describe '#active?' do
    before { cert.certificate = mock_cert }

    it { is_expected.to be_active }
  end

  describe '#exipred?' do
    before { cert.expires_at = 3.days.ago }

    it { is_expected.to be_expired }
  end

  describe '#get' do
    it 'will ask Lets\'Encrypt for (re)new certificate' do
      expect_any_instance_of(LetsEncrypt::Certificate).to receive(:verify).and_return(true)
      expect_any_instance_of(LetsEncrypt::Certificate).to receive(:issue).and_return(true)
      subject.get
    end
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
          certificate: mock_cert,
          key: key
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
          certificate: mock_cert,
          key: key
        )
      end

      it { expect(LetsEncrypt::Redis).to have_received(:delete) }
    end
  end

  describe '#verify' do
    subject(:cert) { LetsEncrypt::Certificate.new(domain: 'example.com') }

    let(:acme_client) { double(Acme::Client) }
    let(:acme_order) { double }
    let(:acme_authorization) { double }
    let(:acme_challenge) { double }

    before do
      allow(LetsEncrypt).to receive(:client).and_return(acme_client)
      allow(acme_client).to receive(:new_order).and_return(acme_order)
      allow(acme_order).to receive(:reload)
      allow(acme_order).to receive(:finalize)
      allow(acme_order).to receive(:authorizations).and_return([acme_authorization])
      allow(acme_authorization).to receive(:http).and_return(acme_challenge)
      allow(acme_challenge).to receive(:reload)

      allow(acme_challenge).to receive(:filename).and_return('.well-known/acme-challenge/path').at_least(1).times
      allow(acme_challenge).to receive(:file_content).and_return('content').at_least(1).times

      allow(acme_challenge).to receive(:request_validation).and_return(true).at_least(1).times
    end

    describe 'when status is valid' do
      before { allow(acme_challenge).to receive(:status).and_return('valid') }

      it { is_expected.to have_attributes(verify: true) }
    end

    describe 'when status is pending to valid' do
      before do
        allow(acme_challenge).to receive(:status).and_return('pending')
        allow(acme_challenge).to receive(:status).and_return('valid')
      end

      it { is_expected.to have_attributes(verify: true) }
    end

    describe 'when Acme::Client::Error is raised' do
      before do
        allow(acme_challenge).to receive(:status).and_raise(Acme::Client::Error::BadNonce)
        allow(acme_challenge).to receive(:status).and_return('valid')
      end

      it { is_expected.to have_attributes(verify: true) }
    end
  end

  describe '#issue' do
    subject(:cert) { LetsEncrypt::Certificate.new(domain: 'example.com', key: key) }

    let(:acme_client) { double(Acme::Client) }
    let(:acme_order) { double }
    let(:mock_cert) { OpenSSL::X509::Certificate.new }

    before do
      key = OpenSSL::PKey::RSA.new 2048
      mock_cert.public_key = key.public_key
      mock_cert.subject = OpenSSL::X509::Name.parse('CN=example.com/C=EE')
      mock_cert.not_before = Time.zone.now
      mock_cert.not_after = 1.month.from_now
      mock_cert.sign(key, OpenSSL::Digest.new('SHA256'))

      allow(LetsEncrypt).to receive(:client).and_return(acme_client)
      allow(acme_client).to receive(:new_order).and_return(acme_order)
      allow(acme_order).to receive(:finalize)
      allow(acme_order).to receive(:certificate).and_return(mock_cert.to_pem)
      allow(acme_order).to receive(:status).and_return('success')
    end

    it { is_expected.to have_attributes(issue: true) }
  end
end
