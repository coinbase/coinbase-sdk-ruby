# frozen_string_literal: true

describe Coinbase::FundQuote do
  subject(:fund_quote) { described_class.new(model) }

  let(:network_id) { :base_sepolia }
  let(:whole_amount) { '123.45' }
  let(:crypto_amount_model) do
    build(:crypto_amount_model, network_id, whole_amount: whole_amount)
  end
  let(:crypto_amount) { build(:crypto_amount, model: crypto_amount_model) }
  let(:fiat_amount_model) { build(:fiat_amount_model) }
  let(:buy_fee_model) { build(:fiat_amount_model, amount: '0.45') }
  let(:transfer_fee_model) { build(:crypto_amount_model, network_id, :eth, whole_amount: '1.01') }
  let(:transfer_fee) { build(:crypto_amount, model: transfer_fee_model) }
  let(:key) { build(:key) }
  let(:address_id) { key.address.to_s }
  let(:model) do
    build(
      :fund_quote_model,
      network_id,
      key: key,
      crypto_amount: crypto_amount_model,
      fiat_amount: fiat_amount_model,
      buy_fee: buy_fee_model,
      transfer_fee: transfer_fee_model
    )
  end
  let(:eth_asset) { build(:asset, network_id, :eth) }

  let(:fund_api) { instance_double(Coinbase::Client::FundApi) }

  before do
    allow(Coinbase::Client::FundApi).to receive(:new).and_return(fund_api)

    allow(Coinbase::Asset)
      .to receive(:fetch)
      .with(network_id, :eth)
      .and_return(eth_asset)
    allow(Coinbase::Asset)
      .to receive(:fetch)
      .with(network_id, :gwei)
      .and_return(build(:asset, network_id, :gwei))
    allow(Coinbase::Asset)
      .to receive(:from_model)
      .with(satisfy { |model| model.asset_id == 'eth' })
      .and_return(eth_asset)
  end

  describe '.create' do
    subject(:created_quote) do
      described_class.create(
        wallet_id: wallet_id,
        address_id: address_id,
        amount: amount,
        asset_id: asset_id,
        network: network_id
      )
    end

    let(:wallet_id) { SecureRandom.uuid }
    let(:asset_id) { eth_asset.asset_id }
    let(:amount) { 123.45 }
    let(:expected_atomic_amount) { '123450000000000000000' }

    before do
      allow(fund_api).to receive(:create_fund_quote).and_return(model)

      created_quote
    end

    it 'creates a Fund Quote' do
      expect(created_quote).to be_a(described_class)
    end

    it 'creates the fund quote' do
      expect(fund_api).to have_received(:create_fund_quote).with(
        wallet_id,
        address_id,
        {
          asset_id: 'eth',
          amount: expected_atomic_amount
        }
      )
    end

    context 'when the asset is not a primary denomination' do
      let(:asset_id) { :gwei }
      let(:amount) { 4567.89 }
      let(:expected_atomic_amount) { '4567890000000' }

      it 'creates a fund quote' do
        expect(created_quote).to be_a(described_class)
      end

      it 'creates the fund quote in the primary denomination' do
        expect(fund_api).to have_received(:create_fund_quote).with(
          wallet_id,
          address_id,
          {
            asset_id: 'eth',
            amount: expected_atomic_amount
          }
        )
      end
    end
  end

  describe '#initialize' do
    it 'initializes a Fund Quote' do
      expect(fund_quote).to be_a(described_class)
    end

    context 'when the model is not a Fund Quote model' do
      let(:model) { build(:balance_model) }

      it 'raises an error' do
        expect { fund_quote }.to raise_error(ArgumentError)
      end
    end
  end

  describe '#id' do
    it 'returns the ID of the Fund Quote' do
      expect(fund_quote.id).to eq(model.fund_quote_id)
    end
  end

  describe '#network' do
    it 'returns the network' do
      expect(fund_quote.network.id).to eq(network_id)
    end
  end

  describe '#wallet_id' do
    it 'returns the wallet ID' do
      expect(fund_quote.wallet_id).to eq(model.wallet_id)
    end
  end

  describe '#address_id' do
    it 'returns the address ID' do
      expect(fund_quote.address_id).to eq(address_id)
    end
  end

  describe '#asset' do
    it 'returns the asset' do
      expect(fund_quote.asset.asset_id).to eq(crypto_amount.asset.asset_id)
    end
  end

  describe '#amount' do
    it 'returns the crypto amount' do
      expect(fund_quote.amount).to be_a(Coinbase::CryptoAmount)
    end

    it 'returns the correct amount' do
      expect(fund_quote.amount.amount).to eq(crypto_amount.amount)
    end

    it 'returns the correct asset' do
      expect(fund_quote.amount.asset.asset_id).to eq(:eth)
    end
  end

  describe '#fiat_amount' do
    it 'returns the fiat amount' do
      expect(fund_quote.fiat_amount).to be_a(Coinbase::FiatAmount)
    end

    it 'returns the correct amount' do
      expect(fund_quote.fiat_amount.amount).to eq(BigDecimal(fiat_amount_model.amount))
    end

    it 'returns the correct currency' do
      expect(fund_quote.fiat_amount.currency).to eq(fiat_amount_model.currency.to_sym)
    end
  end

  describe '#buy_fee' do
    it 'returns a fiat amount' do
      expect(fund_quote.buy_fee).to be_a(Coinbase::FiatAmount)
    end

    it 'returns the correct amount' do
      expect(fund_quote.buy_fee.amount).to eq(BigDecimal(buy_fee_model.amount))
    end

    it 'returns the correct currency' do
      expect(fund_quote.buy_fee.currency).to eq(buy_fee_model.currency.to_sym)
    end
  end

  describe '#transfer_fee' do
    it 'returns a crypto amount' do
      expect(fund_quote.transfer_fee).to be_a(Coinbase::CryptoAmount)
    end

    it 'returns the correct amount' do
      expect(fund_quote.transfer_fee.amount).to eq(transfer_fee.amount)
    end

    it 'returns the correct asset' do
      expect(fund_quote.transfer_fee.asset.asset_id).to eq(:eth)
    end
  end

  describe '#inspect' do
    it 'includes fund quote details' do # rubocop:disable RSpec/ExampleLength
      expect(fund_quote.inspect).to include(
        Coinbase.to_sym(network_id).to_s,
        model.wallet_id,
        address_id,
        crypto_amount.to_s,
        BigDecimal(fiat_amount_model.amount).to_i.to_s,
        fiat_amount_model.currency,
        BigDecimal(buy_fee_model.amount).to_i.to_s,
        buy_fee_model.currency,
        transfer_fee.to_s
      )
    end
  end
end
