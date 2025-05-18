# frozen_string_literal: true

require 'rails_helper'

RSpec.describe LetsEncrypt::VerificationsController, type: :controller do
  routes { LetsEncrypt::Engine.routes }

  subject { get :show, params: { verification_path: } }
  let(:verification_path) { :invalid_path }

  describe 'with invalid path' do
    it { is_expected.to be_not_found }
  end

  describe 'with default model' do
    let!(:certificate) do
      LetsEncrypt.certificate_model.create(
        domain: 'example.com',
        verification_path: '.well-known/acme-challenge/valid_path',
        verification_string: 'verification'
      )
    end
    let(:verification_path) { 'valid_path' }

    it { is_expected.to be_ok }
    it { is_expected.to have_attributes(body: certificate.verification_string) }
  end

  describe 'with customize model' do
    let!(:certificate) do
      LetsEncrypt.certificate_model.create(
        domain: 'example.com',
        verification_path: '.well-known/acme-challenge/valid_path',
        verification_string: 'verification'
      )
    end
    let(:verification_path) { 'valid_path' }

    before { LetsEncrypt.config.certificate_model = 'OtherModel' }
    after { LetsEncrypt.config.certificate_model = 'LetsEncrypt::Certificate' }

    it { is_expected.to be_ok }
    it { is_expected.to have_attributes(body: certificate.verification_string) }
  end
end
