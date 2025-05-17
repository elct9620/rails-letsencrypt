# frozen_string_literal: true

require 'rails_helper'

RSpec.describe LetsEncrypt::RenewCertificatesJob, type: :job do
  include_context 'with renewable certificate'

  let(:certificate) { LetsEncrypt::Certificate.new(domain: 'example.com') }

  before do
    ActiveJob::Base.queue_adapter = :test

    allow(LetsEncrypt::Certificate).to receive(:renewable).and_return([certificate])
  end

  describe 'when renew success' do
    before do
      LetsEncrypt::RenewCertificatesJob.perform_now
    end

    it { expect(acme_order).to have_received(:status) { 'success' } }
  end

  describe 'renew failed' do
    before do
      LetsEncrypt::RenewCertificatesJob.perform_now
    end

    it { expect(certificate.renew_after).to(satisfy { |time| time > Time.zone.now }) }
  end
end
