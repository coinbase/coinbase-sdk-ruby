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
end
