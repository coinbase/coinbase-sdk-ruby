# frozen_string_literal: true

describe Coinbase::Network do
  let(:network) do
    described_class.new(
      network_id: :ethereum,
      display_name: 'Ethereum',
      protocol_family: 'evm',
      is_testnet: false,
      native_asset_id: :eth,
      chain_id: 1
    )
  end

  describe '#initialize' do
    it 'initializes a network' do
      expect(network).to be_a(described_class)
    end
  end

  describe '#chain_id' do
    it 'returns the chain ID of the network' do
      expect(network.chain_id).to eq(1)
    end
  end

  describe '#native_asset_id' do
    it 'returns the native asset ID of the network' do
      expect(network.native_asset_id).to eq(:eth)
    end
  end
end
