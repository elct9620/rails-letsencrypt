# frozen_string_literal: true

RSpec.describe LetsEncrypt::RenewCertificatesJob, type: :job do
  let(:certificate) { LetsEncrypt::Certificate.new }

  before do
    ActiveJob::Base.queue_adapter = :test

    allow(LetsEncrypt::Certificate).to receive(:renewable).and_return([certificate])
  end

  describe 'when renew success' do
    before do
      allow(certificate).to receive(:renew).and_return(true)

      LetsEncrypt::RenewCertificatesJob.perform_now
    end

    it { expect(certificate).to have_received(:renew) }
  end

  describe 'renew failed' do
    before do
      allow(certificate).to receive(:renew).and_return(false)
      allow(certificate).to receive(:update).with(renew_after: an_instance_of(ActiveSupport::TimeWithZone))

      LetsEncrypt::RenewCertificatesJob.perform_now
    end
    it 'schedule next renew to 1 days from now' do
      expect(certificate).to have_received(:update).with(renew_after: an_instance_of(ActiveSupport::TimeWithZone))
    end
  end
end
