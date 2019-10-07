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
    class OtherModel < LetsEncrypt::Certificate
      after_update :success

      def success
        'success'
      end
    end

    before(:each) do
      LetsEncrypt.config.certificate_model = 'OtherModel'
      LetsEncrypt.certificate_model.create(
        domain: 'example.com',
        verification_path: '.well-known/acme-challenge/valid_path',
        verification_string: 'verification'
      )
    end

    it 'update data' do
      expect_any_instance_of(OtherModel).to receive(:success)
      LetsEncrypt.certificate_model.first.update(renew_after: 3.days.ago)
    end
  end
end
