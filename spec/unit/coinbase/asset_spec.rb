# frozen_string_literal: true

describe Coinbase::Asset do
  describe '.from_model' do
    subject(:asset) { described_class.from_model(asset_model) }

    let(:asset_model) do
      Coinbase::Client::Asset.new(network_id: 'base-sepolia', asset_id: 'eth', decimals: 18)
    end

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

    context 'when the asset_id is gwei' do
      subject(:asset) { described_class.from_model(asset_model, asset_id: asset_id) }

      let(:asset_id) { :gwei }

      it 'sets the asset_id' do
        expect(asset.asset_id).to eq(asset_id)
      end

      it 'sets the decimals' do
        expect(asset.decimals).to eq(Coinbase::GWEI_DECIMALS)
      end
    end

    context 'when the asset_id is wei' do
      subject(:asset) { described_class.from_model(asset_model, asset_id: asset_id) }

      let(:asset_id) { :wei }

      it 'sets the asset_id' do
        expect(asset.asset_id).to eq(asset_id)
      end

      it 'sets the decimals' do
        expect(asset.decimals).to eq(0)
      end
    end

    context 'when the asset_id is invalid' do
      subject(:asset) { described_class.from_model(asset_model, asset_id: asset_id) }

      let(:asset_id) { :other }

      it 'raises an error' do
        expect { asset }.to raise_error(ArgumentError)
      end
    end

    context 'when the asset is not a Coinbase::Client::Asset' do
      it 'raises an error' do
        expect do
          described_class.new(build(:balance_model))
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

  describe '.fetch' do
    subject(:asset) { described_class.fetch(network_id, asset_id) }

    let(:assets_api) { instance_double(Coinbase::Client::AssetsApi) }
    let(:asset_id) { :eth }
    let(:network_id) { :base_sepolia }
    let(:asset_model) { build(:asset_model) }

    before do
      allow(Coinbase::Client::AssetsApi).to receive(:new).and_return(assets_api)
      allow(assets_api).to receive(:get_asset).and_return(asset_model)
    end

    it 'is called with the asset_id' do
      asset

      expect(assets_api).to have_received(:get_asset).with('base-sepolia', asset_id.to_s)
    end

    it 'returns an Asset' do
      expect(asset).to be_a(described_class)
    end

    it 'sets the network_id' do
      expect(asset.network_id).to eq(:base_sepolia)
    end

    it 'sets the asset_id' do
      expect(asset.asset_id).to eq(asset_id)
    end

    it 'sets the decimals' do
      expect(asset.decimals).to eq(18)
    end

    context 'when the asset_id is gwei' do
      let(:asset_id) { :gwei }

      it 'fetches the `eth` primary denomination' do
        asset

        expect(assets_api).to have_received(:get_asset).with('base-sepolia', 'eth')
      end

      it 'sets the asset_id' do
        expect(asset.asset_id).to eq(asset_id)
      end

      it 'sets the decimals' do
        expect(asset.decimals).to eq(Coinbase::GWEI_DECIMALS)
      end
    end

    context 'when the asset_id is wei' do
      let(:asset_id) { :wei }

      it 'fetches the `eth` primary denomination' do
        asset

        expect(assets_api).to have_received(:get_asset).with('base-sepolia', 'eth')
      end

      it 'sets the asset_id' do
        expect(asset.asset_id).to eq(asset_id)
      end

      it 'sets the decimals' do
        expect(asset.decimals).to eq(0)
      end
    end
  end

  describe '#initialize' do
    subject(:asset) do
      described_class.new(
        network_id: network_id,
        asset_id: asset_id,
        decimals: decimals
      )
    end

    let(:network_id) { :base_sepolia }
    let(:asset_id) { :eth }
    let(:decimals) { 7 }

    it 'sets the network_id' do
      expect(asset.network_id).to eq(network_id)
    end

    it 'sets the asset_id' do
      expect(asset.asset_id).to eq(asset_id)
    end

    it 'does not set the address_id' do
      expect(asset.address_id).to be_nil
    end

    it 'sets the decimals' do
      expect(asset.decimals).to eq(decimals)
    end

    context 'when address_id is specified' do
      subject(:asset) do
        described_class.new(
          network_id: network_id,
          asset_id: asset_id,
          address_id: address_id,
          decimals: decimals
        )
      end

      let(:address_id) { '0x036CbD53842' }
      let(:network_id) { :base_sepolia }

      it 'sets the address_id' do
        expect(asset.address_id).to eq(address_id)
      end
    end
  end

  describe '#from_atomic_amount' do
    subject(:asset) do
      described_class.new(
        network_id: network_id,
        asset_id: asset_id,
        decimals: 7
      )
    end

    let(:amount) { BigDecimal('123000000000000000000') }
    let(:network_id) { :base_sepolia }
    let(:asset_id) { :eth }

    it 'returns the whole amount' do
      expect(asset.from_atomic_amount(amount)).to eq(BigDecimal('12_300_000_000_000'))
    end
  end

  describe '#to_atomic_amount' do
    subject(:asset) do
      described_class.new(
        network_id: network_id,
        asset_id: asset_id,
        decimals: 7
      )
    end

    let(:amount) { 123.0 }
    let(:network_id) { :base_sepolia }
    let(:asset_id) { :eth }

    it 'returns the atomic amount' do
      expect(asset.to_atomic_amount(amount)).to eq(BigDecimal('1_230_000_000'))
    end
  end

  describe '#primary_denomination' do
    subject(:asset) do
      described_class.new(
        network_id: :base_sepolia,
        asset_id: asset_id,
        decimals: 7
      )
    end

    %i[wei gwei eth].each do |asset_id|
      context "when the asset_id is #{asset_id}" do
        let(:asset_id) { asset_id }

        it 'returns :eth' do
          expect(asset.primary_denomination).to eq(:eth)
        end
      end
    end

    context 'when the asset_id is not wei or gwei' do
      let(:asset_id) { :other }

      it 'returns the asset_id' do
        expect(asset.primary_denomination).to eq(:other)
      end
    end
  end

  describe '#inspect' do
    subject(:asset) do
      described_class.new(network_id: network_id, asset_id: asset_id, decimals: decimals)
    end

    let(:network_id) { :base_sepolia }
    let(:asset_id) { :eth }
    let(:decimals) { 7 }

    it 'includes asset details' do
      expect(asset.inspect).to include(
        Coinbase.to_sym(network_id).to_s,
        asset_id.to_s,
        decimals.to_s
      )
    end

    it 'returns the same value as to_s' do
      expect(asset.inspect).to eq(asset.to_s)
    end

    context 'when the asset contains an address_id' do
      subject(:asset) do
        described_class.new(
          network_id: network_id,
          asset_id: asset_id,
          address_id: address_id,
          decimals: decimals
        )
      end

      let(:address_id) { '0x036CbD53842' }

      it 'includes the address id' do
        expect(asset.inspect).to include(address_id)
      end
    end
  end
end
