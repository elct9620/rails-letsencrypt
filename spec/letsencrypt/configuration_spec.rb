# frozen_string_literal: true

require 'rails_helper'

RSpec.describe LetsEncrypt::Configuration do
  describe '#use_redis?' do
    it 'reture is user enable save to redis value' do
      subject.save_to_redis = true
      expect(subject.use_redis?).to be_truthy
    end
  end

  describe '#use_staging?' do
    it 'return same value as #use_staging config attribute' do
      subject.use_staging = true
      expect(subject.use_staging?).to eq(subject.use_staging)
    end
  end

  describe 'customize certificate model' do
    before(:each) do
      stub_const('OtherModel', Class.new(LetsEncrypt::Certificate))

      OtherModel.after_update :success
      OtherModel.class_eval do
        def success
          'success'
        end
      end

      LetsEncrypt.config.certificate_model = 'OtherModel'
      allow(LetsEncrypt).to receive(:certificate_model).and_return(OtherModel)
      LetsEncrypt.certificate_model.create(
        domain: 'example.com',
        verification_path: '.well-known/acme-challenge/valid_path',
        verification_string: 'verification'
      )
    end
    after { LetsEncrypt.config.certificate_model = 'LetsEncrypt::Certificate' }
    it 'update data' do
      expect_any_instance_of(OtherModel).to receive(:success)
      LetsEncrypt.certificate_model.first.update(renew_after: 3.days.ago)
    end
  end
end
