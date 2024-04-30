# frozen_string_literal: true

describe Coinbase::Authenticator do
  let(:app) { double('Faraday::Connection') }
  let(:authenticator) { described_class.new(app) }
  let(:data) { JSON.parse(File.read('spec/fixtures/cdp_api_key.json')) }
  let(:api_key_name) { data['name'] }
  let(:api_key_private_key) { data['privateKey'] }

  before do
    allow(Coinbase.configuration).to receive(:api_key_name).and_return(api_key_name)
    allow(Coinbase.configuration).to receive(:api_key_private_key).and_return(api_key_private_key)
  end

  describe '#call' do
    let(:env) { double('Faraday::Env') }

    it 'adds the JWT to the Authorization header' do
      allow(env).to receive(:method).and_return('GET')
      allow(env).to receive(:url).and_return(URI('https://cdp.api.coinbase.com/v1/users/me'))
      allow(env).to receive(:request_headers).and_return({})
      expect(app).to receive(:call) do |env|
        expect(env.request_headers['Authorization']).to start_with('Bearer ')
      end

      authenticator.call(env)
    end
  end

  describe '#build_jwt' do
    let(:uri) { 'https://cdp.api.coinbase.com/v1/users/me' }

    it 'builds a JWT for the given endpoint URI' do
      jwt = authenticator.build_jwt(uri)

      expect(jwt).to be_a(String)
    end
  end
end
