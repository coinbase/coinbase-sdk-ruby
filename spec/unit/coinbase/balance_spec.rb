# frozen_string_literal: true

describe Coinbase::Balance do
  describe '.from_model' do
    let(:amount) { BigDecimal('123.0') }
    let(:balance_model) { instance_double('Coinbase::Client::Balance', asset: asset, amount: amount) }

    subject(:balance) { described_class.from_model(balance_model) }

    context 'when the asset is :eth' do
      let(:asset) { instance_double('Coinbase::Client::Asset', asset_id: 'ETH') }

      it 'returns a new Balance object with the correct amount' do
        expect(balance.amount).to eq(amount / BigDecimal(Coinbase::WEI_PER_ETHER))
      end

      it 'returns a new Balance object with the correct asset_id' do
        expect(balance.asset_id).to eq(:eth)
      end
    end

    context 'when the asset is :usdc' do
      let(:asset) { instance_double('Coinbase::Client::Asset', asset_id: 'USDC') }

      it 'returns a new Balance object with the correct amount' do
        expect(balance.amount).to eq(amount / BigDecimal(Coinbase::ATOMIC_UNITS_PER_USDC))
      end

      it 'returns a new Balance object with the correct asset_id' do
        expect(balance.asset_id).to eq(:usdc)
      end
    end

    context 'when the asset is :weth' do
      let(:asset) { instance_double('Coinbase::Client::Asset', asset_id: 'WETH') }

      it 'returns a new Balance object with the correct amount' do
        expect(balance.amount).to eq(amount / BigDecimal(Coinbase::WEI_PER_ETHER))
      end

      it 'returns a new Balance object with the correct asset_id' do
        expect(balance.asset_id).to eq(:weth)
      end
    end

    context 'when the asset is another asset type' do
      let(:asset) { instance_double('Coinbase::Client::Asset', asset_id: 'OTHER') }

      it 'returns a new Balance object with the correct amount' do
        expect(balance.amount).to eq(amount)
      end

      it 'returns a new Balance object with the correct asset_id' do
        expect(balance.asset_id).to eq(:other)
      end
    end
  end

  describe '.from_model_and_asset_id' do
    let(:amount) { BigDecimal('123.0') }
    let(:balance_model) { instance_double('Coinbase::Client::Balance', asset: asset, amount: amount) }

    subject(:balance) { described_class.from_model_and_asset_id(balance_model, asset_id) }

    context 'when the balance model asset is :eth' do
      let(:asset) { instance_double('Coinbase::Client::Asset', asset_id: 'ETH') }

      context 'and the specified asset_id is :eth' do
        let(:asset_id) { :eth }

        it 'returns a new Balance object with the correct amount' do
          expect(balance.amount).to eq(amount / BigDecimal(Coinbase::WEI_PER_ETHER))
        end

        it 'returns a new Balance object with the correct asset_id' do
          expect(balance.asset_id).to eq(asset_id)
        end
      end

      context 'and the specified asset_id is :gwei' do
        let(:asset_id) { :gwei }

        it 'returns a new Balance object with the correct amount' do
          expect(balance.amount).to eq(amount / BigDecimal(Coinbase::GWEI_PER_ETHER))
        end

        it 'returns a new Balance object with the correct asset_id' do
          expect(balance.asset_id).to eq(asset_id)
        end
      end

      context 'and the specified asset_id is :wei' do
        let(:asset_id) { :wei }

        it 'returns a new Balance object with the correct amount' do
          expect(balance.amount).to eq(amount)
        end

        it 'returns a new Balance object with the correct asset_id' do
          expect(balance.asset_id).to eq(asset_id)
        end
      end
    end

    context 'when the asset is :usdc' do
      let(:asset) { instance_double('Coinbase::Client::Asset', asset_id: 'USDC') }
      let(:asset_id) { :usdc }

      it 'returns a new Balance object with the correct amount' do
        expect(balance.amount).to eq(amount / BigDecimal(Coinbase::ATOMIC_UNITS_PER_USDC))
      end

      it 'returns a new Balance object with the correct asset_id' do
        expect(balance.asset_id).to eq(asset_id)
      end
    end

    context 'when the asset is :weth' do
      let(:asset) { instance_double('Coinbase::Client::Asset', asset_id: 'WETH') }
      let(:asset_id) { :weth }

      it 'returns a new Balance object with the correct amount' do
        expect(balance.amount).to eq(amount / BigDecimal(Coinbase::WEI_PER_ETHER))
      end

      it 'returns a new Balance object with the correct asset_id' do
        expect(balance.asset_id).to eq(asset_id)
      end
    end

    context 'when the asset is another asset type' do
      let(:asset) { instance_double('Coinbase::Client::Asset', asset_id: 'OTHER') }
      let(:asset_id) { :other }

      it 'returns a new Balance object with the correct amount' do
        expect(balance.amount).to eq(amount)
      end

      it 'returns a new Balance object with the correct asset_id' do
        expect(balance.asset_id).to eq(asset_id)
      end
    end
  end

  describe '#initialize' do
    let(:amount) { BigDecimal('123.0') }
    let(:asset_id) { :eth }

    subject(:balance) { described_class.new(amount: amount, asset_id: asset_id) }

    it 'sets the amount' do
      expect(balance.amount).to eq(amount)
    end

    it 'sets the asset_id' do
      expect(balance.asset_id).to eq(asset_id)
    end
  end

  describe '#inspect' do
    let(:amount) { BigDecimal('123.0') }
    let(:asset_id) { :eth }

    subject(:balance) { described_class.new(amount: amount, asset_id: asset_id) }

    it 'includes balance details' do
      expect(balance.inspect).to include('123', 'eth')
    end

    it 'returns the same value as to_s' do
      expect(balance.inspect).to eq(balance.to_s)
    end
  end
end
