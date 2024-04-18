# frozen_string_literal: true

describe Coinbase do
  describe '#init' do
    it 'loads environment variables' do
      Coinbase.init
      expect(ENV['BASE_SEPOLIA_RPC_URL']).to eq('https://sepolia.base.org')
    end
  end
end
