# frozen_string_literal: true

describe Coinbase::Balance do
  describe '.from_model' do
    let(:amount) { BigDecimal('123.0') }
    let(:balance_model) { instance_double('Coinbase::Client::Balance', asset: asset, amount: amount) }

    subject { described_class.from_model(balance_model) }

    context 'when the asset is :eth' do
      let(:asset) { instance_double('Coinbase::Client::Asset', asset_id: 'ETH') }

      it 'returns a new Balance object with the correct amount' do
        expect(subject.amount).to eq(amount / BigDecimal(Coinbase::WEI_PER_ETHER))
      end

      it 'returns a new Balance object with the correct asset_id' do
        expect(subject.asset_id).to eq(:eth)
      end
    end

    context 'when the asset is :usdc' do
      let(:asset) { instance_double('Coinbase::Client::Asset', asset_id: 'USDC') }

      it 'returns a new Balance object with the correct amount' do
        expect(subject.amount).to eq(amount / BigDecimal(Coinbase::ATOMIC_UNITS_PER_USDC))
      end

      it 'returns a new Balance object with the correct asset_id' do
        expect(subject.asset_id).to eq(:usdc)
      end
    end

    context 'when the asset is :weth' do
      let(:asset) { instance_double('Coinbase::Client::Asset', asset_id: 'WETH') }

      it 'returns a new Balance object with the correct amount' do
        expect(subject.amount).to eq(amount / BigDecimal(Coinbase::WEI_PER_ETHER))
      end

      it 'returns a new Balance object with the correct asset_id' do
        expect(subject.asset_id).to eq(:weth)
      end
    end

    context 'when the asset is another asset type' do
      let(:asset) { instance_double('Coinbase::Client::Asset', asset_id: 'OTHER') }

      it 'returns a new Balance object with the correct amount' do
        expect(subject.amount).to eq(amount)
      end

      it 'returns a new Balance object with the correct asset_id' do
        expect(subject.asset_id).to eq(:other)
      end
    end
  end

  describe '#initialize' do
    let(:amount) { BigDecimal('123.0') }
    let(:asset_id) { :eth }

    subject { described_class.new(amount: amount, asset_id: asset_id) }

    it 'sets the amount' do
      expect(subject.amount).to eq(amount)
    end

    it 'sets the asset_id' do
      expect(subject.asset_id).to eq(asset_id)
    end
  end
end
