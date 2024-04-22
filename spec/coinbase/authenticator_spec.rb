# frozen_string_literal: true

describe Coinbase::Authenticator do
  let(:app) { double('Faraday::Connection' )}
  let(:authenticator) { described_class.new(app) }

  after(:each) do
    Coinbase.api_key_name = nil
    Coinbase.api_key_private_key = nil
  end

  describe '#build_jwt' do
    let(:uri) { 'https://cdp.api.coinbase.com/v1/users/me' }
    let(:data) { JSON.parse(File.read('spec/fixtures/cdp_api_key.json')) }

    before do
      Coinbase.init(data['name'], data['privateKey'])
    end

    it 'builds a JWT for the given endpoint URI' do
      jwt = authenticator.build_jwt(uri)

      expect(jwt).to be_a(String)
    end

    it 'raises an error if the API key name is not set' do
      Coinbase.api_key_name = nil

      expect { authenticator.build_jwt(uri) }.to raise_error('API key name is not set')
    end

    it 'raises an error if the API key private key is not set' do
      Coinbase.api_key_private_key = nil

      expect { authenticator.build_jwt(uri) }.to raise_error('API key private key is not set')
    end
  end
end
