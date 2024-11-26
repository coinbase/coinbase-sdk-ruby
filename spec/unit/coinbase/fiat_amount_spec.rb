# frozen_string_literal: true

describe Coinbase::FiatAmount do
  let(:amount_string) { '123.0' }
  let(:amount) { BigDecimal('123.0') }
  let(:currency) { 'usd' }
  let(:fiat_amount_model) do
    build(:fiat_amount_model, amount: amount_string, currency: currency)
  end

  describe '.from_model' do
    subject(:fiat_amount) { described_class.from_model(fiat_amount_model) }

    it 'returns a FiatAmount object' do
      expect(fiat_amount).to be_a(described_class)
    end

    it 'sets the correct amount' do
      expect(fiat_amount.amount).to eq(amount)
    end

    it 'sets the correct currency' do
      expect(fiat_amount.currency).to eq(:usd)
    end

    context 'when the model is not a FiatAmount' do
      let(:fiat_amount_model) { build(:balance_model, :base_sepolia) }

      it 'raises an ArgumentError' do
        expect do
          fiat_amount
        end.to raise_error(ArgumentError, 'model must be a Coinbase::Client::FiatAmount')
      end
    end
  end

  describe '#initialize' do
    subject(:fiat_amount) { described_class.new(amount: amount_string, currency: currency) }

    it 'sets the BigDecimal amount' do
      expect(fiat_amount.amount).to eq(amount)
    end

    it 'sets the currency symbol' do
      expect(fiat_amount.currency).to eq(:usd)
    end

    context 'when the amount is a BigDecimal' do
      subject(:fiat_amount) { described_class.new(amount: amount, currency: currency) }

      it 'sets the BigDecimal amount' do
        expect(fiat_amount.amount).to eq(amount)
      end
    end
  end

  describe '#inspect' do
    subject(:fiat_amount) { described_class.new(amount: amount, currency: currency) }

    let(:amount) { BigDecimal('123.456') }

    it 'includes fiat_amount details' do
      expect(fiat_amount.inspect).to include('123.456', 'usd')
    end

    it 'returns the same value as to_s' do
      expect(fiat_amount.inspect).to eq(fiat_amount.to_s)
    end
  end
end
