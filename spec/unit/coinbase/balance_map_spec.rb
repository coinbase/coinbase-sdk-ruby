# frozen_string_literal: true

describe Coinbase::BalanceMap do
  let(:eth_asset) { build(:asset_model) }

  describe '.from_balances' do
    let(:eth_balance) { build(:balance_model, amount: BigDecimal('123.0')) }
    let(:eth_atomic_amount) { Coinbase::Asset.from_model(eth_balance.asset).from_atomic_amount(eth_balance.amount) }

    let(:usdc_balance) { build(:balance_model, :usdc, amount: BigDecimal('456.0')) }
    let(:usdc_atomic_amount) { Coinbase::Asset.from_model(usdc_balance.asset).from_atomic_amount(usdc_balance.amount) }

    let(:weth_balance) { build(:balance_model, :weth, amount: BigDecimal('789.0')) }
    let(:weth_atomic_amount) { Coinbase::Asset.from_model(weth_balance.asset).from_atomic_amount(weth_balance.amount) }

    let(:balances) { [eth_balance, usdc_balance, weth_balance] }

    subject { described_class.from_balances(balances) }

    it 'returns a new BalanceMap object with the correct balances' do
      expect(subject[:eth]).to eq(eth_atomic_amount)
      expect(subject[:usdc]).to eq(usdc_atomic_amount)
      expect(subject[:weth]).to eq(weth_atomic_amount)
    end
  end

  describe '#add' do
    let(:amount) { BigDecimal('123.0') }
    let(:asset_id) { :eth }
    let(:asset) { Coinbase::Asset.from_model(eth_asset) }
    let(:balance) { Coinbase::Balance.new(amount: amount, asset: asset) }

    subject { described_class.new }

    it 'sets the amount' do
      subject.add(balance)

      expect(subject[asset_id]).to eq(amount)
    end

    context 'when the balance is not a Coinbase::Balance' do
      let(:balance) { instance_double('Coinbase::Asset') }

      it 'raises an ArgumentError' do
        expect { subject.add(balance) }.to raise_error(ArgumentError)
      end
    end
  end

  describe '#to_s' do
    let(:amount) { BigDecimal('123.0') }
    let(:asset_id) { :eth }
    let(:asset) { Coinbase::Asset.from_model(eth_asset) }
    let(:balance) { Coinbase::Balance.new(amount: amount, asset: asset) }

    let(:expected_result) { { eth: '123' }.to_s }

    subject { described_class.new }

    before { subject.add(balance) }

    it 'returns a string representation of asset_id to floating-point number' do
      expect(subject.to_s).to eq({ eth: '123' }.to_s)
    end
  end
end
