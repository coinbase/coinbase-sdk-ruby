# frozen_string_literal: true

describe Coinbase::Authenticator do
  let(:app) do
    Class.new do
      def call(env)
        "callable #{env.request_headers['middle']}"
      end
    end.new
  end
  let(:authenticator) { described_class.new(app) }
  let(:data) { JSON.parse(File.read('spec/fixtures/cdp_api_key.json')) }
  let(:api_key_name) { data['name'] }
  let(:api_key_private_key) { data['privateKey'] }

  before do
    allow(Coinbase.configuration).to receive_messages(
      api_key_name: api_key_name,
      api_key_private_key: api_key_private_key
    )
  end

  describe '#call' do
    let(:env) { instance_double(Faraday::Env) }

    before do
      allow(env).to receive_messages(
        method: 'GET',
        url: URI('https://cdp.api.coinbase.com/v1/users/me'),
        request_headers: {}
      )

      allow(app).to receive(:call)

      authenticator.call(env)
    end

    it 'adds the JWT to the Authorization header' do # rubocop:disable RSpec/MultipleExpectations
      expect(app).to have_received(:call) do |env|
        expect(env.request_headers['Authorization']).to start_with('Bearer ')
      end
    end
  end

  describe '#build_jwt' do
    subject(:jwt) { authenticator.build_jwt(uri) }

    let(:uri) { 'https://cdp.api.coinbase.com/v1/users/me' }

    it 'builds a JWT for the given endpoint URI' do
      expect(jwt).to be_a(String)
    end

    context 'when an API key is not configured' do
      let(:api_key_private_key) { nil }

      it 'raises an exception' do
        expect { jwt }.to raise_error(Coinbase::InvalidConfiguration, /API key not configured/)
      end
    end
  end
end
