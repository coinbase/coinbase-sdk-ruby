describe Coinbase::Network do
  let(:eth) { Coinbase::Asset.new(network_id: :base_sepolia, asset_id: :eth, display_name: 'Ether') }
  let(:usdc) { Coinbase::Asset.new(network_id: :base_sepolia, asset_id: :usdc, display_name: 'USD Coin') }
  let(:network) do
    described_class.new(
      network_id: :ethereum,
      display_name: 'Ethereum',
      protocol_family: 'evm',
      is_testnet: false,
      assets: [eth, usdc],
      native_asset_id: :eth,
      chain_id: 1
    )
  end

  describe '#initialize' do
    it 'initializes a network' do
      expect(network.chain_id).to eq(1)
    end

    it 'raises an error if the native asset is not found' do
      expect do
        described_class.new(
          network_id: :ethereum,
          display_name: 'Ethereum',
          protocol_family: 'evm',
          is_testnet: false,
          assets: [eth, usdc],
          native_asset_id: :btc,
          chain_id: 1
        )
      end.to raise_error(ArgumentError, 'Native Asset not found')
    end
  end

  describe '#list_assets' do
    it 'lists the assets supported by the network' do
      expect(network.list_assets).to include(eth, usdc)
    end
  end

  describe '#get_asset' do
    it 'gets an asset by ID' do
      expect(network.get_asset(:eth)).to eq(eth)
    end

    it 'returns nil if the asset is not found' do
      expect(network.get_asset(:btc)).to be_nil
    end
  end
end
