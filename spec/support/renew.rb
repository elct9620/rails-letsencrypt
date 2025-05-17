# frozen_string_literal: true

RSpec.shared_context 'with renewable certificate' do
  let(:acme_client) { spy(Acme::Client) }
  let(:acme_order) { spy(Acme::Client::Resources::Order) }
  let(:acme_authorization) { spy(Acme::Client::Resources::Authorization) }
  let(:acme_challenge) { spy(Acme::Client::Resources::Challenges::HTTP01) }
  let(:renewed_cert) { OpenSSL::X509::Certificate.new }

  let(:not_before) { Time.zone.now }
  let(:not_after) { 1.month.from_now }

  before do
    key = OpenSSL::PKey::RSA.new 2048
    renewed_cert.public_key = key.public_key
    renewed_cert.subject = OpenSSL::X509::Name.parse('CN=example.com/C=EE')
    renewed_cert.not_before = not_before
    renewed_cert.not_after = not_after
    renewed_cert.sign(key, OpenSSL::Digest.new('SHA256'))

    allow(LetsEncrypt).to receive(:client).and_return(acme_client)
    allow(acme_client).to receive(:new_order).and_return(acme_order)

    allow(acme_order).to receive(:authorizations).and_return([acme_authorization])
    allow(acme_order).to receive(:status).and_return('success')
    allow(acme_order).to receive(:certificate).and_return(renewed_cert.to_pem)

    allow(acme_authorization).to receive(:http).and_return(acme_challenge)

    allow(acme_challenge).to receive(:status).and_return('pending')
    allow(acme_challenge).to receive(:status).and_return('valid')
    allow(acme_challenge).to receive(:filename).and_return('.well-known/acme-challenge/path').at_least(1).times
    allow(acme_challenge).to receive(:file_content).and_return('content').at_least(1).times
    allow(acme_challenge).to receive(:request_validation).and_return(true).at_least(1).times
  end
end
