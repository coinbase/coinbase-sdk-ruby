# frozen_string_literal: true

describe Coinbase::StakingOperation do
  let(:wallet_id) { 'wallet-id' }
  let(:network_id) { :ethereum_holesky }
  let(:address_id) { 'address_id' }
  let(:staking_operation_model) do
    instance_double(Coinbase::Client::StakingOperation, status: :initialized, id: 'some_id', wallet_id: wallet_id,
                                                        network_id: 'ethereum-holesky', address_id: 'address_id')
  end
  let(:staking_operation) { described_class.new(staking_operation_model) }
  let(:transaction_model) { instance_double(Coinbase::Client::Transaction) }
  let(:transaction) { instance_double(Coinbase::Transaction) }
  let(:key) { instance_double(Eth::Key) }
  let(:eth_asset_model) do
    Coinbase::Client::Asset.new(network_id: 'ethereum-holesky', asset_id: 'eth', decimals: 18)
  end
  let(:eth_asset) { Coinbase::Asset.from_model(eth_asset_model) }
  let(:hex_encoded_transaction) { '0xdeadbeef' }

  let(:stake_api) { double('Coinbase::Client::StakeApi') }

  before(:each) do
    allow(Coinbase::Client::StakeApi).to receive(:new).and_return(stake_api)
  end

  before do
    allow(staking_operation_model).to receive(:transactions).and_return([transaction_model])
    allow(Coinbase::Transaction).to receive(:new).and_return(transaction)
    allow(transaction).to receive(:signed?).and_return(false)
    allow(transaction).to receive(:sign)
    allow(Coinbase::Asset).to receive(:fetch).and_return(eth_asset)
    allow(Coinbase::Client::StakeApi).to receive(:new).and_return(stake_api)
    allow(stake_api).to receive(:build_staking_operation).and_return(staking_operation_model)
    allow(stake_api).to receive(:create_staking_operation).and_return(staking_operation_model)
    allow(stake_api).to receive(:broadcast_staking_operation)
    raw_tx = double 'EthereumTransaction'
    allow(transaction).to receive(:raw).and_return(raw_tx)
    allow(raw_tx).to receive(:hex).and_return(hex_encoded_transaction)
  end

  describe '.build' do
    let(:amount) { 1 }
    let(:asset_id) { :eth }
    let(:action) { :stake }
    let(:mode) { :partial }
    let(:options) { {} }

    subject { described_class.build(amount, network_id, asset_id, address_id, action, mode, options) }

    it 'calls Asset.fetch' do
      subject

      expect(Coinbase::Asset).to have_received(:fetch).with(network_id, :eth)
    end

    it 'calls StakeApi.build_staking_operation' do
      subject

      expect(stake_api).to have_received(:build_staking_operation).with(
        {
          asset_id: 'eth',
          address_id: address_id,
          action: :stake,
          network_id: 'ethereum-holesky',
          options: {
            amount: '1000000000000000000',
            mode: :partial
          }
        }
      )
    end
  end

  describe '.create' do
    let(:amount) { 1 }
    let(:asset_id) { :eth }
    let(:action) { :stake }
    let(:mode) { :partial }
    let(:options) { {} }

    subject { described_class.create(amount, network_id, asset_id, address_id, wallet_id, action, mode, options) }

    it 'calls Asset.fetch' do
      subject

      expect(Coinbase::Asset).to have_received(:fetch).with(network_id, :eth)
    end

    it 'calls StakeApi.build_staking_operation' do
      subject

      expect(stake_api).to have_received(:create_staking_operation).with(
        wallet_id,
        address_id,
        {
          asset_id: 'eth',
          address_id: address_id,
          action: :stake,
          network_id: 'ethereum-holesky',
          options: {
            amount: '1000000000000000000',
            mode: :partial
          }
        }
      )
    end
  end

  describe '#initialize' do
    it 'creates a transaction for each transaction model' do
      expect(Coinbase::Transaction).to receive(:new).with(transaction_model)

      staking_operation
    end
  end

  describe '#sign' do
    it 'signs each transaction' do
      staking_operation.sign(key)

      expect(transaction).to have_received(:sign).with(key)
    end

    it 'does not sign already signed transactions' do
      allow(transaction).to receive(:signed?).and_return(true)

      staking_operation.sign(key)

      expect(transaction).not_to have_received(:sign)
    end
  end

  describe '#wait!' do
    let(:updated_staking_operation_model) do
      Coinbase::Client::StakingOperation.new(
        status: 'complete',
        transactions: [transaction_model]
      )
    end

    before do
      allow(staking_operation).to receive(:sleep)

      allow(stake_api)
        .to receive(:get_external_staking_operation)
        .with(network_id, address_id, staking_operation.id)
        .and_return(staking_operation_model, staking_operation_model, updated_staking_operation_model)
    end

    context 'when the staking operation is completed' do
      it 'returns the completed StakingOperation' do
        expect(staking_operation.wait!).to eq(staking_operation)
        expect(staking_operation.status).to eq('complete')
      end
    end

    context 'when the staking operation times out' do
      let(:updated_staking_operation_model) do
        Coinbase::Client::StakingOperation.new(
          status: 'initialized',
          transactions: [transaction_model]
        )
      end

      it 'raises a Timeout::Error' do
        expect { staking_operation.wait!(0.2, 0.00001) }.to raise_error(Timeout::Error, 'Staking Operation timed out')
      end
    end
  end

  describe '#broadcast!' do
    let(:transaction_signed) { true }

    before do
      allow(transaction).to receive(:signed?).and_return(transaction_signed)
    end

    it 'calls broadcast with the transaction' do
      staking_operation.broadcast!

      expect(stake_api).to have_received(:broadcast_staking_operation).with(
        wallet_id,
        address_id,
        staking_operation.id,
        { signed_payload: hex_encoded_transaction, transaction_index: 0 }
      )
    end

    context 'when the transaction is not signed' do
      let(:transaction_signed) { false }

      it 'raises a transaction not signed exception' do
        expect { staking_operation.broadcast! }.to raise_error Coinbase::TransactionNotSignedError
      end
    end
  end
end
