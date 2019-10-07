# frozen_string_literal: true

require 'rails_helper'

RSpec.describe LetsEncrypt do
  let(:tempfile) { Tempfile.new }
  let(:key) { OpenSSL::PKey::RSA.new(2048) }

  before :each do
    LetsEncrypt.class_eval do
      @private_key = nil
      @endpoint = nil
    end

    LetsEncrypt.config.private_key_path = tempfile.path
  end

  describe '#generate_private_key' do
    it 'create a new private key' do
      key = LetsEncrypt.generate_private_key
      expect(LetsEncrypt.private_key.to_s).to eq(key.to_s)
    end
  end

  describe '#register' do
    let(:acme_client) { double(::Acme::Client) }
    let(:acme_account) { double }

    it 'register new account to Let\'s Encrypt' do
      tempfile.write(key.to_s)
      tempfile.rewind

      allow(LetsEncrypt).to receive(:client).and_return(acme_client)
      allow(acme_client).to receive(:new_account).and_return(acme_account)
      allow(acme_account).to receive(:kid).and_return('')

      LetsEncrypt.register('example@example.com')
    end
  end

  describe 'certificate_model' do
    class OtherModel < LetsEncrypt::Certificate
    end
    before do
      LetsEncrypt.config.certificate_model = 'OtherModel'
      LetsEncrypt.stub(:certificate_model) { LetsEncrypt.config.certificate_model.constantize }
    end
    after { LetsEncrypt.config.certificate_model = 'LetsEncrypt::Certificate' }
    it 'set the certificate_model to customize model' do
      expect(LetsEncrypt.certificate_model).to eq('OtherModel'.constantize)
    end
  end
end
