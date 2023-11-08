# frozen_string_literal: true

require 'rails_helper'

RSpec.describe LetsEncrypt do
  let(:tempfile) { Tempfile.new }
  let(:key) { OpenSSL::PKey::RSA.new(2048) }

  before do
    LetsEncrypt.class_eval do
      @private_key = nil
      @endpoint = nil
    end

    LetsEncrypt.config.private_key_path = tempfile.path
  end

  describe '#generate_private_key' do
    let!(:key) { LetsEncrypt.generate_private_key }

    it { expect(LetsEncrypt.private_key.to_s).to eq(key.to_s) }
  end

  describe '#register' do
    let(:acme_client) { double(Acme::Client) }
    let(:acme_account) { double }

    before do
      tempfile.write(key.to_s)
      tempfile.rewind

      allow(LetsEncrypt).to receive(:client).and_return(acme_client)
      allow(acme_client).to receive(:new_account).and_return(acme_account)
      allow(acme_account).to receive(:kid).and_return('')
    end

    it { expect(LetsEncrypt.register('example@example.com')).to be_truthy }
  end

  describe 'certificate_model' do
    before do
      stub_const('OtherModel', Class.new(LetsEncrypt::Certificate))
      LetsEncrypt.config.certificate_model = 'OtherModel'

      allow(LetsEncrypt).to receive(:certificate_model) { LetsEncrypt.config.certificate_model.constantize }
    end

    after { LetsEncrypt.config.certificate_model = 'LetsEncrypt::Certificate' }

    it { expect(LetsEncrypt).to have_attributes(certificate_model: OtherModel) }
  end
end
