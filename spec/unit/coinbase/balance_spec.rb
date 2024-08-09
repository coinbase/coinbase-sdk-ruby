# frozen_string_literal: true

describe Coinbase::Balance do
  let(:amount) { BigDecimal('123.0') }
  let(:balance_model) { instance_double(Coinbase::Client::Balance, asset: asset, amount: amount) }
  let(:eth_asset) { build(:asset_model) }

  describe '.from_model' do
    subject(:balance) { described_class.from_model(balance_model) }

    context 'when the asset is :eth' do
      let(:asset) { eth_asset }

      it 'returns a Balance object' do
        expect(balance).to be_a(described_class)
      end

      it 'sets the correct amount' do
        expect(balance.amount).to eq(amount / BigDecimal(10).power(eth_asset.decimals))
      end

      it 'sets the correct asset_id' do
        expect(balance.asset_id).to eq(:eth)
      end
    end

    context 'when the asset is other' do
      let(:decimals) { 9 }
      let(:asset) { build(:asset_model, asset_id: 'other', decimals: decimals) }

      it 'returns a Balance object' do
        expect(balance).to be_a(described_class)
      end

      it 'sets the correct amount' do
        expect(balance.amount).to eq(amount / BigDecimal(10).power(decimals))
      end

      it 'sets the correct asset_id' do
        expect(balance.asset_id).to eq(:other)
      end
    end
  end

  describe '.from_model_and_asset_id' do
    subject(:balance) { described_class.from_model_and_asset_id(balance_model, asset_id) }

    context 'when the balance model asset is :eth' do
      let(:asset) { eth_asset }

      context 'when the specified asset_id is :eth' do
        let(:asset_id) { :eth }

        it 'returns a new Balance object with the correct amount' do
          expect(balance.amount).to eq(amount / BigDecimal(10).power(eth_asset.decimals))
        end

        it 'returns a new Balance object with the correct asset_id' do
          expect(balance.asset_id).to eq(asset_id)
        end
      end

      context 'when the specified asset_id is :gwei' do
        let(:asset_id) { :gwei }

        it 'returns a new Balance object with the correct amount' do
          expect(balance.amount).to eq(amount / BigDecimal(10).power(Coinbase::GWEI_DECIMALS))
        end

        it 'returns a new Balance object with the correct asset_id' do
          expect(balance.asset_id).to eq(asset_id)
        end
      end

      context 'when the specified asset_id is :wei' do
        let(:asset_id) { :wei }

        it 'returns a new Balance object with the correct amount' do
          expect(balance.amount).to eq(amount)
        end

        it 'returns a new Balance object with the correct asset_id' do
          expect(balance.asset_id).to eq(asset_id)
        end
      end

      context 'when the specified asset_id is another asset type' do
        let(:asset_id) { :other }

        it 'raise an error' do
          expect { balance }.to raise_error(ArgumentError)
        end
      end
    end

    context 'when the asset is not eth' do
      let(:decimals) { 9 }
      let(:asset_id) { :other }
      let(:asset) { build(:asset_model, asset_id: 'other', decimals: decimals) }

      it 'returns a new Balance object with the correct amount' do
        expect(balance.amount).to eq(amount / BigDecimal(10).power(decimals))
      end

      it 'returns a new Balance object with the correct asset_id' do
        expect(balance.asset_id).to eq(asset_id)
      end

      context 'when the asset ID does not match the asset' do
        let(:asset_id) { :different }

        it 'raises an error' do
          expect { balance }.to raise_error(ArgumentError)
        end
      end
    end
  end

  describe '#initialize' do
    subject(:balance) { described_class.new(amount: amount, asset: asset) }

    let(:amount) { BigDecimal('123.0') }
    let(:asset) { Coinbase::Asset.from_model(eth_asset) }

    it 'sets the amount' do
      expect(balance.amount).to eq(amount)
    end

    it 'sets the asset' do
      expect(balance.asset).to eq(asset)
    end

    it "sets the asset_id to the asset's ID" do
      expect(balance.asset_id).to eq(:eth)
    end
  end

  describe '#inspect' do
    subject(:balance) { described_class.new(amount: amount, asset: asset) }

    let(:amount) { BigDecimal('123.0') }
    let(:asset) { Coinbase::Asset.from_model(eth_asset) }

    it 'includes balance details' do
      expect(balance.inspect).to include('123', 'eth')
    end

    it 'returns the same value as to_s' do
      expect(balance.inspect).to eq(balance.to_s)
    end
  end
end
