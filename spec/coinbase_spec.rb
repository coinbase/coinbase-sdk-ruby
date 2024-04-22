# frozen_string_literal: true

describe Coinbase do
  describe '#base_sepolia_rpc_url' do
    it 'returns the Base Sepolia RPC URL' do
      expect(Coinbase.base_sepolia_rpc_url).to eq('https://sepolia.base.org')
    end
  end

  describe '#base_sepolia_rpc_url=' do
    it 'sets the Base Sepolia RPC URL' do
      Coinbase.base_sepolia_rpc_url = 'https://not-sepolia.base.org'
      expect(Coinbase.base_sepolia_rpc_url).to eq('https://not-sepolia.base.org')
    end
  end

  describe '#api_key_name' do
    it 'raises an error if the API key name is not set' do
      expect { Coinbase.api_key_name }.to raise_error('API key name is not set')
    end
  end

  describe '#api_key_name=' do
    it 'sets the API key name' do
      Coinbase.api_key_name = 'my-api-key-name'
      expect(Coinbase.api_key_name).to eq('my-api-key-name')
    end
  end

  describe '#api_key_private_key' do
    it 'raises an error if the API key private key is not set' do
      expect { Coinbase.api_key_private_key }.to raise_error('API key private key is not set')
    end
  end

  describe '#api_key_private_key=' do
    it 'sets the API key private key' do
      Coinbase.api_key_private_key = 'my-api-key-private-key'
      expect(Coinbase.api_key_private_key).to eq('my-api-key-private-key')
    end
  end
end
