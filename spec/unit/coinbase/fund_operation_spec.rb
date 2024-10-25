# frozen_string_literal: true

describe Coinbase::FundOperation do
  subject(:fund_operation) { described_class.new(model) }

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
      :fund_operation_model,
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
    subject(:created_operation) do
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
      allow(fund_api).to receive(:create_fund_operation).and_return(model)
    end

    it 'creates a fund operation' do
      expect(created_operation).to be_a(described_class)
    end

    it 'creates the fund operation via the API' do
      created_operation

      expect(fund_api).to have_received(:create_fund_operation).with(
        wallet_id,
        address_id,
        {
          asset_id: 'eth',
          amount: expected_atomic_amount
        }
      )
    end

    context 'when a quote is provided' do
      subject(:created_operation) do
        described_class.create(
          wallet_id: wallet_id,
          address_id: address_id,
          amount: amount,
          asset_id: asset_id,
          network: network_id,
          quote: quote
        )
      end

      let(:quote) { build(:fund_quote, network_id, :eth) }

      it 'creates a fund operation' do
        expect(created_operation).to be_a(described_class)
      end

      it 'creates the fund operation for the specified quote via the API' do
        created_operation

        expect(fund_api).to have_received(:create_fund_operation).with(
          wallet_id,
          address_id,
          {
            asset_id: 'eth',
            amount: expected_atomic_amount,
            fund_quote_id: quote.id
          }
        )
      end
    end

    context 'when a quote ID is provided' do
      subject(:created_operation) do
        described_class.create(
          wallet_id: wallet_id,
          address_id: address_id,
          amount: amount,
          asset_id: asset_id,
          network: network_id,
          quote: quote_id
        )
      end

      let(:quote_id) { SecureRandom.uuid }

      it 'creates a fund operation' do
        expect(created_operation).to be_a(described_class)
      end

      it 'creates the fund operation for the specified quote ID via the API' do
        created_operation

        expect(fund_api).to have_received(:create_fund_operation).with(
          wallet_id,
          address_id,
          {
            asset_id: 'eth',
            amount: expected_atomic_amount,
            fund_quote_id: quote_id
          }
        )
      end
    end

    context 'when an invalid quote is provided' do
      subject(:created_operation) do
        described_class.create(
          wallet_id: wallet_id,
          address_id: address_id,
          amount: amount,
          asset_id: asset_id,
          network: network_id,
          quote: build(:balance_model, network_id)
        )
      end

      it 'raises an error' do
        expect do
          created_operation
        end.to raise_error(ArgumentError, 'quote must be a FundQuote object or ID')
      end
    end

    context 'when the asset is not a primary denomination' do
      let(:asset_id) { :gwei }
      let(:amount) { 4567.89 }
      let(:expected_atomic_amount) { '4567890000000' }

      it 'creates a fund operation' do
        expect(created_operation).to be_a(described_class)
      end

      it 'creates the fund operation in the primary denomination' do
        created_operation

        expect(fund_api).to have_received(:create_fund_operation).with(
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

  describe '.list' do
    subject(:enumerator) do
      described_class.list(wallet_id: wallet_id, address_id: address_id)
    end

    let(:api) { fund_api }
    let(:wallet_id) { SecureRandom.uuid }
    let(:fetch_params) { ->(page) { [wallet_id, address_id, { limit: 100, page: page }] } }
    let(:resource_list_klass) { Coinbase::Client::FundOperationList }
    let(:item_klass) { described_class }
    let(:item_initialize_args) { nil }
    let(:create_model) do
      ->(id) { build(:fund_operation_model, network_id, fund_operation_id: id) }
    end

    it_behaves_like 'it is a paginated enumerator', :fund_operations
  end

  describe '#initialize' do
    it 'initializes a Fund operation' do
      expect(fund_operation).to be_a(described_class)
    end

    context 'when the model is not a Fund operation model' do
      let(:model) { build(:balance_model) }

      it 'raises an error' do
        expect { fund_operation }.to raise_error(ArgumentError)
      end
    end
  end

  describe '#id' do
    it 'returns the ID of the Fund operation' do
      expect(fund_operation.id).to eq(model.fund_operation_id)
    end
  end

  describe '#network' do
    it 'returns the network' do
      expect(fund_operation.network.id).to eq(network_id)
    end
  end

  describe '#wallet_id' do
    it 'returns the wallet ID' do
      expect(fund_operation.wallet_id).to eq(model.wallet_id)
    end
  end

  describe '#address_id' do
    it 'returns the address ID' do
      expect(fund_operation.address_id).to eq(address_id)
    end
  end

  describe '#asset' do
    it 'returns the asset' do
      expect(fund_operation.asset.asset_id).to eq(crypto_amount.asset.asset_id)
    end
  end

  describe '#amount' do
    it 'returns the crypto amount' do
      expect(fund_operation.amount).to be_a(Coinbase::CryptoAmount)
    end

    it 'returns the correct amount' do
      expect(fund_operation.amount.amount).to eq(crypto_amount.amount)
    end

    it 'returns the correct asset' do
      expect(fund_operation.amount.asset.asset_id).to eq(:eth)
    end
  end

  describe '#fiat_amount' do
    it 'returns the fiat amount' do
      expect(fund_operation.fiat_amount).to be_a(Coinbase::FiatAmount)
    end

    it 'returns the correct amount' do
      expect(fund_operation.fiat_amount.amount).to eq(BigDecimal(fiat_amount_model.amount))
    end

    it 'returns the correct currency' do
      expect(fund_operation.fiat_amount.currency).to eq(fiat_amount_model.currency.to_sym)
    end
  end

  describe '#buy_fee' do
    it 'returns a fiat amount' do
      expect(fund_operation.buy_fee).to be_a(Coinbase::FiatAmount)
    end

    it 'returns the correct amount' do
      expect(fund_operation.buy_fee.amount).to eq(BigDecimal(buy_fee_model.amount))
    end

    it 'returns the correct currency' do
      expect(fund_operation.buy_fee.currency).to eq(buy_fee_model.currency.to_sym)
    end
  end

  describe '#transfer_fee' do
    it 'returns a crypto amount' do
      expect(fund_operation.transfer_fee).to be_a(Coinbase::CryptoAmount)
    end

    it 'returns the correct amount' do
      expect(fund_operation.transfer_fee.amount).to eq(transfer_fee.amount)
    end

    it 'returns the correct asset' do
      expect(fund_operation.transfer_fee.asset.asset_id).to eq(:eth)
    end
  end

  describe '#reload' do
    let(:updated_model) { build(:fund_operation_model, network_id, :complete) }

    before do
      allow(fund_api)
        .to receive(:get_fund_operation)
        .with(fund_operation.wallet_id, fund_operation.address_id, fund_operation.id)
        .and_return(updated_model)
    end

    it 'updates the fund operation' do
      expect(fund_operation.reload.status).to eq(Coinbase::FundOperation::Status::COMPLETE)
    end
  end

  describe '#wait!' do
    before do
      allow(fund_operation).to receive(:sleep) # rubocop:disable RSpec/SubjectStub

      allow(fund_api)
        .to receive(:get_fund_operation)
        .with(fund_operation.wallet_id, fund_operation.address_id, fund_operation.id)
        .and_return(model, model, updated_model)
    end

    context 'when the fund operation is complete' do
      let(:updated_model) { build(:fund_operation_model, network_id, :complete) }

      it 'returns the completed FundOperation' do
        expect(fund_operation.wait!.status).to eq(Coinbase::Transaction::Status::COMPLETE)
      end
    end

    context 'when the fund operation is failed' do
      let(:updated_model) { build(:fund_operation_model, network_id, :failed) }

      it 'returns the failed FundOperation' do
        expect(fund_operation.wait!.status).to eq(Coinbase::Transaction::Status::FAILED)
      end
    end

    context 'when the fund operation times out' do
      let(:updated_model) { build(:fund_operation_model, network_id, :pending) }

      it 'raises a Timeout::Error' do
        expect { fund_operation.wait!(0.2, 0.00001) }.to raise_error(Timeout::Error, 'Fund Operation timed out')
      end
    end
  end

  describe '#inspect' do
    it 'includes fund operation details' do # rubocop:disable RSpec/ExampleLength
      expect(fund_operation.inspect).to include(
        Coinbase.to_sym(network_id).to_s,
        model.fund_operation_id,
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
