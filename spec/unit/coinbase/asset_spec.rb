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

  describe '#initialize' do
    let(:network_id) { :base_sepolia }
    let(:asset_id) { :eth }
    let(:display_name) { 'Ether' }
    let(:address_id) { '0x036CbD53842' }

    subject do
      described_class.new(network_id: network_id, asset_id: asset_id, display_name: display_name,
                          address_id: address_id)
    end

    it 'sets the network_id' do
      expect(subject.network_id).to eq(network_id)
    end

    it 'sets the asset_id' do
      expect(subject.asset_id).to eq(asset_id)
    end

    it 'sets the display_name' do
      expect(subject.display_name).to eq(display_name)
    end

    it 'sets the address_id' do
      expect(subject.address_id).to eq(address_id)
    end
  end
end
