# frozen_string_literal: true

require 'rails_helper'

RSpec.describe LetsEncrypt::VerificationsController, type: :controller do
  routes { LetsEncrypt::Engine.routes }
  class OtherModel < LetsEncrypt::Certificate
  end

  it 'returns 404 status when no valid verification path found' do
    get :show, params: { verification_path: :invalid_path }
    expect(response.status).to eq(404)
  end


  describe 'has certificate' do
    context 'with default model' do
      let!(:certificate) do
        LetsEncrypt.certificate_model.create(
          domain: 'example.com',
          verification_path: '.well-known/acme-challenge/valid_path',
          verification_string: 'verification'
        )
      end
      it 'returns verification string when found verification path' do
        get :show, params: { verification_path: 'valid_path' }
        expect(response.status).to eq(200)
        expect(response.body).to eq(certificate.verification_string)
      end
    end

    context 'with customize model' do
      before { LetsEncrypt.config.certificate_model = 'OtherModel' }
      let!(:certificate) do
        LetsEncrypt.certificate_model.create(
          domain: 'example.com',
          verification_path: '.well-known/acme-challenge/valid_path',
          verification_string: 'verification'
        )
      end
      after { LetsEncrypt.config.certificate_model = 'LetsEncrypt::Certificate' }
      it 'returns verification string when found verification path' do
        get :show, params: { verification_path: 'valid_path' }
        expect(response.status).to eq(200)
        expect(response.body).to eq(certificate.verification_string)
      end
    end
  end
end
