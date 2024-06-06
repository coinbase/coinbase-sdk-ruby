# frozen_string_literal: true

describe Coinbase::Asset do
  describe '.supported?' do
    %i[eth gwei wei usdc weth].each do |asset_id|
      context "when the asset_id is #{asset_id}" do
        it 'returns true' do
          expect(described_class.supported?(asset_id)).to be true
        end
      end
    end

    context 'when the asset_id is not supported' do
      it 'returns false' do
        expect(described_class.supported?(:unsupported)).to be false
      end
    end
  end

  describe '.to_atomic_amount' do
    let(:amount) { 123.0 }

    context 'when the asset_id is :eth' do
      it 'returns the amount in atomic units' do
        expect(described_class.to_atomic_amount(amount, :eth)).to eq(BigDecimal('123000000000000000000'))
      end
    end

    context 'when the asset_id is :gwei' do
      it 'returns the amount in atomic units' do
        expect(described_class.to_atomic_amount(amount, :gwei)).to eq(BigDecimal('123000000000'))
      end
    end

    context 'when the asset_id is :usdc' do
      it 'returns the amount in atomic units' do
        expect(described_class.to_atomic_amount(amount, :usdc)).to eq(BigDecimal('123000000'))
      end
    end

    context 'when the asset_id is :weth' do
      it 'returns the amount in atomic units' do
        expect(described_class.to_atomic_amount(amount, :weth)).to eq(BigDecimal('123000000000000000000'))
      end
    end

    context 'when the asset_id is :wei' do
      it 'returns the amount' do
        expect(described_class.to_atomic_amount(amount, :wei)).to eq(BigDecimal('123.0'))
      end
    end

    context 'when the asset_id is not explicitly handled' do
      it 'returns the amount' do
        expect(described_class.to_atomic_amount(amount, :other)).to eq(BigDecimal('123.0'))
      end
    end
  end

  describe '.from_atomic_amount' do
    let(:atomic_amount) { BigDecimal('123000000000000000000') }

    context 'when the asset_id is :eth' do
      it 'returns the amount in whole units' do
        expect(described_class.from_atomic_amount(atomic_amount, :eth)).to eq(BigDecimal('123.0'))
      end
    end

    context 'when the asset_id is :gwei' do
      it 'returns the amount in gwei' do
        expect(described_class.from_atomic_amount(atomic_amount, :gwei)).to eq(BigDecimal('123000000000'))
      end
    end

    context 'when the asset_id is :usdc' do
      it 'returns the amount in whole units' do
        expect(described_class.from_atomic_amount(atomic_amount, :usdc)).to eq(BigDecimal('123000000000000'))
      end
    end

    context 'when the asset_id is :weth' do
      it 'returns the amount in whole units' do
        expect(described_class.from_atomic_amount(atomic_amount, :weth)).to eq(BigDecimal('123.0'))
      end
    end

    context 'when the asset_id is :wei' do
      it 'returns the amount' do
        expect(described_class.from_atomic_amount(atomic_amount, :wei)).to eq(BigDecimal('123000000000000000000'))
      end
    end
  end

  describe '.primary_denomination' do
    %i[wei gwei].each do |asset_id|
      context "when the asset_id is #{asset_id}" do
        it 'returns :eth' do
          expect(described_class.primary_denomination(asset_id)).to eq(:eth)
        end
      end
    end

    context 'when the asset_id is not wei or gwei' do
      it 'returns the asset_id' do
        expect(described_class.primary_denomination(:other)).to eq(:other)
      end
    end
  end

  describe '.from_model' do
    let(:asset_model) do
      Coinbase::Client::Asset.new(network_id: 'base-sepolia', asset_id: 'eth', decimals: 18)
    end
    subject(:asset) { described_class.from_model(asset_model) }

    it 'returns an Asset' do
      expect(asset).to be_a(described_class)
    end

    it 'sets the network_id' do
      expect(asset.network_id).to eq(:base_sepolia)
    end

    it 'sets the asset_id' do
      expect(asset.asset_id).to eq(:eth)
    end

    it 'sets the decimals' do
      expect(asset.decimals).to eq(18)
    end

    it 'does not set the address_id' do
      expect(asset.address_id).to be_nil
    end

    context 'when the asset is not a Coinbase::Client::Asset' do
      it 'raises an error' do
        expect do
          described_class.from_model(Coinbase::Client::Balance.new)
        end.to raise_error(StandardError)
      end
    end

    context 'when the asset has a contract address' do
      let(:contract_address) { '0x036CbD53842c5426634e7929541eC2318f3dCF7e' }
      let(:asset_model) do
        Coinbase::Client::Asset.new(
          network_id: 'base-sepolia',
          asset_id: 'usdc',
          decimals: 6,
          contract_address: contract_address
        )
      end

      it 'sets the address_id' do
        expect(asset.address_id).to eq(contract_address)
      end
    end
  end

  describe '#initialize' do
    let(:network_id) { :base_sepolia }
    let(:asset_id) { :eth }
    let(:display_name) { 'Ether' }
    let(:address_id) { '0x036CbD53842' }

    subject(:asset) do
      described_class.new(
        network_id: network_id,
        asset_id: asset_id,
        display_name: display_name,
        address_id: address_id
      )
    end

    it 'sets the network_id' do
      expect(asset.network_id).to eq(network_id)
    end

    it 'sets the asset_id' do
      expect(asset.asset_id).to eq(asset_id)
    end

    it 'sets the display_name' do
      expect(asset.display_name).to eq(display_name)
    end

    it 'sets the address_id' do
      expect(asset.address_id).to eq(address_id)
    end

    it 'does not set decimals' do
      expect(asset.decimals).to be_nil
    end

    context 'when decimals is specified' do
      let(:decimals) { 18 }

      subject(:asset) do
        described_class.new(
          network_id: network_id,
          asset_id: asset_id,
          display_name: display_name,
          address_id: address_id,
          decimals: decimals
        )
      end

      it 'sets the decimals' do
        expect(asset.decimals).to eq(decimals)
      end
    end

    context 'when display name is not specified' do
      subject(:asset) do
        described_class.new(network_id: network_id, asset_id: asset_id, address_id: address_id)
      end

      it 'does not set display_name' do
        expect(asset.display_name).to be_nil
      end
    end
  end

  describe '#inspect' do
    let(:network_id) { :base_sepolia }
    let(:asset_id) { :eth }
    let(:display_name) { 'Ether' }

    subject(:asset) do
      described_class.new(
        network_id: network_id,
        asset_id: asset_id,
        display_name: display_name
      )
    end

    it 'includes asset details' do
      expect(asset.inspect).to include(
        Coinbase.to_sym(network_id).to_s,
        asset_id.to_s,
        display_name
      )
    end

    it 'returns the same value as to_s' do
      expect(asset.inspect).to eq(asset.to_s)
    end

    context 'when the asset contains an address_id' do
      let(:address_id) { '0x036CbD53842' }

      subject(:asset) do
        described_class.new(
          network_id: network_id,
          asset_id: asset_id,
          display_name: display_name,
          address_id: address_id
        )
      end

      it 'includes the transaction hash' do
        expect(asset.inspect).to include(address_id)
      end
    end
  end
end
