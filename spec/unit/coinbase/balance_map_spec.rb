# frozen_string_literal: true

describe Coinbase::BalanceMap do
  describe '.from_balances' do
    let(:eth_amount) { BigDecimal('123.0') }
    let(:eth_asset) { instance_double('Coinbase::Client::Asset', asset_id: 'ETH') }
    let(:eth_balance_model) { instance_double('Coinbase::Client::Balance', asset: eth_asset, amount: eth_amount) }

    let(:usdc_amount) { BigDecimal('456.0') }
    let(:usdc_asset) { instance_double('Coinbase::Client::Asset', asset_id: 'USDC') }
    let(:usdc_balance_model) { instance_double('Coinbase::Client::Balance', asset: usdc_asset, amount: usdc_amount) }

    let(:weth_amount) { BigDecimal('789.0') }
    let(:weth_asset) { instance_double('Coinbase::Client::Asset', asset_id: 'WETH') }
    let(:weth_balance_model) { instance_double('Coinbase::Client::Balance', asset: weth_asset, amount: weth_amount) }

    let(:balances) { [eth_balance_model, usdc_balance_model, weth_balance_model] }

    subject { described_class.from_balances(balances) }

    it 'returns a new BalanceMap object with the correct balances' do
      expect(subject[:eth]).to eq(eth_amount / BigDecimal(Coinbase::WEI_PER_ETHER))
      expect(subject[:usdc]).to eq(usdc_amount / BigDecimal(Coinbase::ATOMIC_UNITS_PER_USDC))
      expect(subject[:weth]).to eq(weth_amount / BigDecimal(Coinbase::WEI_PER_ETHER))
    end
  end

  describe '#add' do
    let(:amount) { BigDecimal('123.0') }
    let(:asset_id) { :eth }
    let(:balance) { Coinbase::Balance.new(amount: amount, asset_id: asset_id) }

    subject { described_class.new }

    it 'sets the amount' do
      subject.add(balance)

      expect(subject[asset_id]).to eq(amount)
    end

    context 'when the balance is not a Coinbase::Balance' do
      let(:balance) { instance_double('Coinbase::Balance') }

      it 'raises an ArgumentError' do
        expect { subject.add(balance) }.to raise_error(ArgumentError)
      end
    end
  end

  describe '#to_s' do
    let(:amount) { BigDecimal('123.0') }
    let(:asset_id) { :eth }
    let(:balance) { Coinbase::Balance.new(amount: amount, asset_id: asset_id) }

    let(:expected_result) { { eth: '123' }.to_s }

    subject { described_class.new }

    before { subject.add(balance) }

    it 'returns a string representation of asset_id to floating-point number' do
      expect(subject.to_s).to eq({ eth: '123' }.to_s)
    end
  end
end
