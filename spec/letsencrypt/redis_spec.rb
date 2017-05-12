# frozen_string_literal: true

require 'rails-letsencrypt'

RSpec.describe LetsEncrypt::Redis do
  let(:redis) { double(::Redis) }
  let(:domain) { 'example.com' }
  let(:certificate) do
    LetsEncrypt::Certificate.new(domain: domain, key: '', certificate: '')
  end

  before(:each) do
    allow(::Redis).to receive(:new).and_return(redis)
  end

  describe '#save' do
    it 'saves certificate into redis' do
      expect(redis).to receive(:set).with("#{domain}.key", an_instance_of(String))
      expect(redis).to receive(:set).with("#{domain}.crt", an_instance_of(String))
      LetsEncrypt::Redis.save(certificate)
    end
  end
end
