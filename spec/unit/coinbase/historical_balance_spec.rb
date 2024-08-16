# frozen_string_literal: true

describe Coinbase::HistoricalBalance do
  let(:amount) { BigDecimal('1000000000000000000') }
  let(:network_id) { :ethereum_mainnet }
  let(:eth_asset) { build(:asset_model, network_id) }
  let(:asset) { Coinbase::Asset.from_model(eth_asset) }
  let(:historical_balance_obj) { build(:historical_balance_model, network_id, amount: '1000000000000000000') }

  describe '.from_model' do
    subject(:historical_balance) { described_class.from_model(historical_balance_obj) }

    it 'returns a HistoricalBalance object' do
      expect(historical_balance).to be_a(described_class)
    end

    it 'sets the correct amount' do
      expect(historical_balance.amount).to eq(amount / BigDecimal(10).power(eth_asset.decimals))
    end

    it 'sets the correct block_height' do
      expect(historical_balance.block_height).to eq(BigDecimal('123'))
    end

    it 'sets the correct block_hash' do
      expect(historical_balance.block_hash).to eq('default_block_hash')
    end

    it 'sets the correct asset' do
      expect(historical_balance.asset.asset_id).to eq(asset.asset_id)
    end
  end

  describe '#initialize' do
    subject(:historical_balance) do
      described_class.new(
        amount: amount,
        block_height: BigDecimal('456'),
        block_hash: 'abc123',
        asset: asset
      )
    end

    it 'sets the amount' do
      expect(historical_balance.amount).to eq(amount)
    end

    it 'sets the block_height' do
      expect(historical_balance.block_height).to eq(BigDecimal('456'))
    end

    it 'sets the block_hash' do
      expect(historical_balance.block_hash).to eq('abc123')
    end

    it 'sets the asset' do
      expect(historical_balance.asset).to eq(asset)
    end
  end

  describe '#to_s' do
    subject(:historical_balance) do
      described_class.new(
        amount: '1',
        block_height: BigDecimal('456'),
        block_hash: 'abc123',
        asset: eth_asset
      )
    end

    it 'returns a string representation of the HistoricalBalance' do
      expect(historical_balance.to_s).to eq("Coinbase::HistoricalBalance{amount: '1', block_height: '456', " \
                                            "block_hash: 'abc123', asset: '#{eth_asset}'}")
    end
  end

  describe '#inspect' do
    subject(:historical_balance) do
      described_class.new(
        amount: amount,
        block_height: BigDecimal('456'),
        block_hash: 'abc123',
        asset: eth_asset
      )
    end

    it 'returns the same value as to_s' do
      expect(historical_balance.inspect).to eq(historical_balance.to_s)
    end
  end
end
