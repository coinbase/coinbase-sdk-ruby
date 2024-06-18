# frozen_string_literal: true

describe Coinbase::Network do
  let(:eth) { Coinbase::Asset.new(network_id: :base_sepolia, asset_id: :eth, decimals: 18) }
  let(:usdc) { Coinbase::Asset.new(network_id: :base_sepolia, asset_id: :usdc, decimals: 6) }
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
      expect(network.chain_id).to eq(1)
    end
  end

  describe '#get_asset' do
    before do
      allow(Coinbase::Asset).to receive(:fetch).with(:ethereum, :usdc).and_return(usdc)
    end

    it 'gets an asset by ID' do
      expect(network.get_asset(:usdc)).to eq(usdc)
    end
  end

  describe '#native_asset' do
    before do
      allow(Coinbase::Asset).to receive(:fetch).with(:ethereum, :eth).and_return(eth)
    end

    it 'returns the native asset of the network' do
      expect(network.native_asset).to eq(eth)
    end
  end
end
