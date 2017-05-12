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
    let(:acme_registration) { double }

    it 'register new account to Let\'s Encrypt' do
      tempfile.write(key.to_s)
      tempfile.rewind

      allow(LetsEncrypt).to receive(:client).and_return(acme_client)
      allow(acme_client).to receive(:register).and_return(acme_registration)
      expect(acme_registration).to receive(:agree_terms)

      LetsEncrypt.register('example@example.com')
    end
  end
end
