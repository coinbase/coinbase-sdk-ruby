# frozen_string_literal: true

describe Coinbase do
  after(:each) do
    Coinbase.api_key_name = nil
    Coinbase.api_key_private_key = nil
    Coinbase.api_url = 'api.cdp.coinbase.com'
  end

  describe '#base_sepolia_rpc_url' do
    it 'returns the Base Sepolia RPC URL' do
      expect(Coinbase.configuration.base_sepolia_rpc_url).to eq('https://sepolia.base.org')
    end
  end

  describe '#base_sepolia_rpc_url=' do
    it 'sets the Base Sepolia RPC URL' do
      Coinbase.configuration.base_sepolia_rpc_url = 'https://not-sepolia.base.org'
      expect(Coinbase.configuration.base_sepolia_rpc_url).to eq('https://not-sepolia.base.org')
    end
  end

  describe '#init' do
    it 'initializes the Coinbase SDK with the given API key name and private key' do
      Coinbase.init('api_key_name', 'api_key_private_key')
      expect(Coinbase.api_key_name).to eq('api_key_name')
      expect(Coinbase.api_key_private_key).to eq('api_key_private_key')
    end
  end

  describe '#api_key_name' do
    it 'raises an error if the API key name is not set' do
      expect { Coinbase.api_key_name }.to raise_error('API key name is not set')
    end
  end

  describe '#api_key_private_key' do
    it 'raises an error if the API key private key is not set' do
      expect { Coinbase.api_key_private_key }.to raise_error('API key private key is not set')
    end
  end

  describe '#api_url' do
    it 'returns the API URL' do
      expect(Coinbase.api_url).to eq('api.cdp.coinbase.com')
    end
  end

  describe '#api_url=' do
    it 'sets the API URL' do
      Coinbase.api_url = 'api.cdp.not-coinbase.com'
      expect(Coinbase.api_url).to eq('api.cdp.not-coinbase.com')
    end
  end
end
