# frozen_string_literal: true

require 'rails_helper'

RSpec.describe LetsEncrypt::Certificate do
  let(:intermediaries) { Array.new(3).map { OpenSSL::X590::Certificate.new } }
  let(:ca) { OpenSSL::X509::Certificate.new }

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
    it 'save certificate into redis' do
      expect(LetsEncrypt::Redis).to receive(:save)
      LetsEncrypt.config.save_to_redis = true
      subject.domain = 'example.com'
      subject.save
    end
  end
end
