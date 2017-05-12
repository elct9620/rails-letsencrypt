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
end
