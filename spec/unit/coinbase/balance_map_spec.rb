# frozen_string_literal: true

describe Coinbase::BalanceMap do
  let(:eth_asset) { build(:asset_model) }

  describe '.from_balances' do
    subject(:balance_map) { described_class.from_balances(balances) }

    let(:eth_balance) { build(:balance_model, amount: BigDecimal('123.0')) }
    let(:eth_atomic_amount) { Coinbase::Asset.from_model(eth_balance.asset).from_atomic_amount(eth_balance.amount) }

    let(:usdc_balance) { build(:balance_model, :usdc, amount: BigDecimal('456.0')) }
    let(:usdc_atomic_amount) { Coinbase::Asset.from_model(usdc_balance.asset).from_atomic_amount(usdc_balance.amount) }

    let(:weth_balance) { build(:balance_model, :weth, amount: BigDecimal('789.0')) }
    let(:weth_atomic_amount) { Coinbase::Asset.from_model(weth_balance.asset).from_atomic_amount(weth_balance.amount) }

    let(:balances) { [eth_balance, usdc_balance, weth_balance] }

    it 'returns a new BalanceMap object with the correct balances' do
      expect(balance_map).to eq(
        eth: eth_atomic_amount,
        usdc: usdc_atomic_amount,
        weth: weth_atomic_amount
      )
    end
  end

  describe '#add' do
    subject(:balance_map) { described_class.new }

    let(:amount) { BigDecimal('123.0') }
    let(:asset_id) { :eth }
    let(:asset) { Coinbase::Asset.from_model(eth_asset) }
    let(:balance) { Coinbase::Balance.new(amount: amount, asset: asset) }

    it 'sets the amount' do
      balance_map.add(balance)

      expect(balance_map[asset_id]).to eq(amount)
    end

    context 'when the balance is not a Coinbase::Balance' do
      let(:balance) { instance_double(Coinbase::Asset) }

      it 'raises an ArgumentError' do
        expect { balance_map.add(balance) }.to raise_error(ArgumentError)
      end
    end
  end

  describe '#to_s' do
    subject(:balance_map) { described_class.new }

    let(:amount) { BigDecimal('123.0') }
    let(:balance) { build(:balance, whole_amount: amount) }

    let(:expected_result) { { eth: '123' }.to_s }

    before { balance_map.add(balance) }

    it 'returns a string representation of asset_id to floating-point number' do
      expect(balance_map.to_s).to eq({ eth: '123' }.to_s)
    end
  end
end
