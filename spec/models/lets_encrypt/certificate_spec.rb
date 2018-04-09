# frozen_string_literal: true

require 'rails_helper'

RSpec.describe LetsEncrypt::Certificate do
  let(:intermediaries) { Array.new(3).map { OpenSSL::X509::Certificate.new } }
  let(:ca) { OpenSSL::X509::Certificate.new }

  before(:each) do
    LetsEncrypt.config.save_to_redis = false
  end

  describe '#active?' do
    it 'return true when certificate exists' do
      subject.certificate = ca
      expect(subject.active?).to be_truthy
    end
  end

  describe '#exipred?' do
    it 'return true when certificate is not renew' do
      subject.expires_at = 3.days.ago
      expect(subject.expired?).to be_truthy
    end
  end

  describe '#get' do
    it 'will ask Lets\'Encrypt for (re)new certificate' do
      expect_any_instance_of(LetsEncrypt::Certificate).to receive(:verify).and_return(true)
      expect_any_instance_of(LetsEncrypt::Certificate).to receive(:issue).and_return(true)
      subject.get
    end
  end

  describe '#save_to_redis' do
    it 'doesnt save certificate if it is blank' do
      expect(LetsEncrypt::Redis).to_not receive(:save)
      LetsEncrypt.config.save_to_redis = true
      subject.domain = 'example.com'
      subject.save
    end

    it 'saves certificate into redis' do
      expect(LetsEncrypt::Redis).to receive(:save)
      LetsEncrypt.config.save_to_redis = true
      subject.domain = 'example.com'
      subject.certificate = 'CERTIFICATE'
      subject.key = 'KEY'
      subject.save
    end
  end

  describe '#verify' do
    let(:acme_client) { double(::Acme::Client) }
    let(:acme_authorization) { double }
    let(:acme_challenge) { double }

    before :each do
      subject.domain = 'example.com'

      allow(LetsEncrypt).to receive(:client).and_return(acme_client)
      allow(acme_client).to receive(:authorize).and_return(acme_authorization)
      allow(acme_authorization).to receive(:http01).and_return(acme_challenge)

      # rubocop:disable Metrics/LineLength
      expect(acme_challenge).to receive(:filename).and_return('.well-known/acme-challenge/path').at_least(1).times
      expect(acme_challenge).to receive(:file_content).and_return('content').at_least(1).times

      expect(acme_challenge).to receive(:request_verification).and_return(true).at_least(1).times
      # rubocop:enable Metrics/LineLength
    end

    it 'ask for Let\'s Encrypt to verify domain' do
      expect(acme_challenge)
        .to receive(:verify_status).and_return('valid').at_least(1).times
      subject.verify
    end

    it 'wait verify status is pending' do
      expect(acme_challenge).to receive(:verify_status).and_return('pending')
      expect(acme_challenge)
        .to receive(:verify_status).and_return('valid').at_least(1).times
      subject.verify
    end

    it 'retry when Acme::Client has error' do
      expect(acme_challenge)
        .to receive(:verify_status).and_raise(::Acme::Client::Error::BadNonce)
      expect(acme_challenge)
        .to receive(:verify_status).and_return('valid').at_least(1).times
      subject.verify
    end
  end

  describe '#issue' do
    let(:acme_client) { double(::Acme::Client) }
    let(:acme_cert) { double }

    before :each do
      subject.domain = 'example.com'
      subject.key = OpenSSL::PKey::RSA.new(2048)

      allow(LetsEncrypt).to receive(:client).and_return(acme_client)
      allow(acme_client).to receive(:new_certificate).and_return(acme_cert)
      allow(ca).to receive(:not_after).and_return(1.month.from_now)
    end

    it 'create new signed certificate' do
      expect(acme_cert).to receive(:to_pem).and_return(ca.to_s)
      expect(acme_cert).to receive(:chain_to_pem).and_return(intermediaries.join)
      expect(acme_cert).to receive(:x509).and_return(ca)
      subject.issue
    end
  end
end
