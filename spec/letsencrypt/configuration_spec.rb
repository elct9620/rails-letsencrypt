# frozen_string_literal: true

require 'rails_helper'

RSpec.describe LetsEncrypt::Configuration do
  subject(:config) { LetsEncrypt::Configuration.new }

  describe '#use_redis?' do
    before { config.save_to_redis = true }

    it { is_expected.to be_use_redis }
  end

  describe '#use_staging?' do
    before { config.use_staging = true }

    it { is_expected.to be_use_staging }
  end

  describe 'customize certificate model' do
    before(:each) { config.certificate_model = 'OtherModel' }
    after { LetsEncrypt.config.certificate_model = 'LetsEncrypt::Certificate' }

    it { is_expected.to have_attributes(certificate_model: 'OtherModel') }
  end
end
