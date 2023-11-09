# frozen_string_literal: true

require 'rails_helper'

RSpec.describe LetsEncrypt::Redis do
  let(:redis) { double(Redis) }
  let(:domain) { 'example.com' }
  let(:certificate) do
    LetsEncrypt::Certificate.new(domain: domain, key: 'KEY', certificate: 'CERTIFICATE')
  end

  before(:each) do
    allow(Redis).to receive(:new).and_return(redis)
  end

  after do
    # Reset connection because redis double will work only for single example
    LetsEncrypt::Redis.instance_variable_set('@connection', nil)
  end

  describe '#save' do
    before do
      allow(redis).to receive(:set).with("#{domain}.key", an_instance_of(String))
      allow(redis).to receive(:set).with("#{domain}.crt", an_instance_of(String))

      LetsEncrypt::Redis.save(certificate)
    end

    it { expect(redis).to have_received(:set).with("#{domain}.key", 'KEY') }
    it { expect(redis).to have_received(:set).with("#{domain}.crt", 'CERTIFICATE') }

    describe 'when key and certificate is empty' do
      let(:certificate) do
        LetsEncrypt::Certificate.new(domain: domain, key: '', certificate: '')
      end

      it { expect(redis).not_to have_received(:set).with("#{domain}.key", an_instance_of(String)) }
      it { expect(redis).not_to have_received(:set).with("#{domain}.crt", an_instance_of(String)) }
    end
  end

  describe '#delete' do
    before do
      allow(redis).to receive(:del).with("#{domain}.key")
      allow(redis).to receive(:del).with("#{domain}.crt")

      LetsEncrypt::Redis.delete(certificate)
    end

    it { expect(redis).to have_received(:del).with("#{domain}.key") }
    it { expect(redis).to have_received(:del).with("#{domain}.crt") }
  end
end
