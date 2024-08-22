# frozen_string_literal: true

describe Coinbase::StakingOperation do
  let(:wallet_id) { 'wallet_id' }
  let(:network_id) { :ethereum_holesky }
  let(:address_id) { 'address_id' }
  let(:metadata) { nil }
  let(:staking_operation_model) do
    instance_double(
      Coinbase::Client::StakingOperation,
      status: :initialized,
      id: 'some_id',
      wallet_id: wallet_id,
      network_id: 'ethereum-holesky',
      address_id: 'address_id',
      transactions: [],
      metadata: metadata
    )
  end
  let(:staking_operation) { described_class.new(staking_operation_model) }
  let(:transaction_model) { instance_double(Coinbase::Client::Transaction) }
  let(:transaction) { instance_double(Coinbase::Transaction) }
  let(:key) { instance_double(Eth::Key) }
  let(:eth_asset_model) { build(:asset_model, :ethereum_holesky) }
  let(:eth_asset) { Coinbase::Asset.from_model(eth_asset_model) }
  let(:hex_encoded_transaction) { '0xdeadbeef' }

  let(:stake_api) { instance_double(Coinbase::Client::StakeApi) }
  let(:wallet_stake_api) { instance_double(Coinbase::Client::WalletStakeApi) }
  let(:raw_tx) { instance_double(Eth::Tx::Eip1559) }

  before do
    allow(Coinbase::Client::StakeApi).to receive(:new).and_return(stake_api)
    allow(Coinbase::Client::WalletStakeApi).to receive(:new).and_return(wallet_stake_api)

    allow(staking_operation_model).to receive(:transactions).and_return([transaction_model])
    allow(transaction_model).to receive(:unsigned_payload).and_return('some_unsigned_payload')
    allow(Coinbase::Transaction).to receive(:new).and_return(transaction)
    allow(transaction).to receive(:sign)
    allow(transaction).to receive(:unsigned_payload).and_return('some_unsigned_payload')
    allow(Coinbase::Asset).to receive(:fetch).and_return(eth_asset)
    allow(stake_api).to receive_messages(
      build_staking_operation: staking_operation_model
    )
    allow(wallet_stake_api).to receive_messages(
      create_staking_operation: staking_operation_model
    )
    allow(wallet_stake_api).to receive(:broadcast_staking_operation)
    allow(transaction).to receive_messages(signed?: false, raw: raw_tx)
    allow(raw_tx).to receive(:hex).and_return(hex_encoded_transaction)
  end

  describe '.build' do
    subject(:staking_operation) do
      described_class.build(amount, network_id, asset_id, address_id, action, mode, options)
    end

    let(:amount) { 1 }
    let(:asset_id) { :eth }
    let(:action) { :stake }
    let(:mode) { :partial }
    let(:options) { {} }

    before { staking_operation }

    it 'fetches the asset' do
      expect(Coinbase::Asset).to have_received(:fetch).with(network_id, :eth)
    end

    it 'builds the staking operation' do
      expect(stake_api).to have_received(:build_staking_operation).with(
        asset_id: 'eth',
        address_id: address_id,
        action: :stake,
        network_id: 'ethereum-holesky',
        options: {
          amount: '1000000000000000000',
          mode: :partial
        }
      )
    end
  end

  describe '.create' do
    subject(:staking_operation) do
      described_class.create(amount, network_id, asset_id, address_id, wallet_id, action, mode, options)
    end

    let(:amount) { 1 }
    let(:asset_id) { :eth }
    let(:action) { :stake }
    let(:mode) { :partial }
    let(:options) { {} }

    before { staking_operation }

    it 'fetches the asset' do
      expect(Coinbase::Asset).to have_received(:fetch).with(network_id, :eth)
    end

    it 'creates the staking operation' do # rubocop:disable RSpec/ExampleLength
      expect(wallet_stake_api).to have_received(:create_staking_operation).with(
        wallet_id,
        address_id,
        asset_id: 'eth',
        address_id: address_id,
        action: :stake,
        network_id: 'ethereum-holesky',
        options: {
          amount: '1000000000000000000',
          mode: :partial
        }
      )
    end
  end

  describe '.fetch' do
    subject(:staking_operation) { described_class.fetch(network_id, address_id, 'some_id') }

    before do
      allow(stake_api).to receive_messages(
        get_external_staking_operation: staking_operation_model
      )
      allow(wallet_stake_api).to receive_messages(
        get_staking_operation: staking_operation_model
      )
    end

    it 'fetches the external staking operation' do
      staking_operation

      expect(stake_api)
        .to have_received(:get_external_staking_operation)
        .with(network_id, address_id, 'some_id')
    end

    it { is_expected.to be_a described_class }

    it 'has the correct id' do
      expect(staking_operation.id).to eq(staking_operation_model.id)
    end

    context 'when a wallet_id is provided' do
      subject(:staking_operation) do
        described_class.fetch(network_id, address_id, 'some_id', wallet_id: wallet_id)
      end

      it 'fetches the wallet-scoped staking operation' do
        staking_operation

        expect(wallet_stake_api)
          .to have_received(:get_staking_operation)
          .with(wallet_id, address_id, 'some_id')
      end
    end
  end

  describe '.reload' do
    subject(:reload) { staking_operation.reload }

    before do
      allow(stake_api)
        .to receive_messages(get_external_staking_operation: staking_operation_model)

      allow(wallet_stake_api)
        .to receive_messages(get_staking_operation: staking_operation_model)
    end

    it 'fetches the staking operation' do
      reload

      expect(wallet_stake_api).to have_received(:get_staking_operation).with(wallet_id, address_id, 'some_id')
    end

    it { is_expected.to be_a described_class }

    it 'has the correct id' do
      expect(reload.id).to eq(staking_operation_model.id)
    end

    context 'when a wallet_id is not provided' do
      let(:staking_operation_model) do
        instance_double(
          Coinbase::Client::StakingOperation,
          status: :initialized,
          id: 'some_id',
          wallet_id: nil,
          network_id: 'ethereum-holesky',
          address_id: 'address_id'
        )
      end

      it 'calls StakeApi.get_external_staking_operation' do
        reload

        expect(stake_api).to have_received(:get_external_staking_operation).with(network_id, address_id, 'some_id')
      end
    end
  end

  describe '#initialize' do
    it 'creates a transaction for each transaction model' do
      staking_operation

      expect(Coinbase::Transaction).to have_received(:new).with(transaction_model)
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
      allow(wallet_stake_api)
        .to receive(:get_staking_operation)
        .with(wallet_id, address_id, staking_operation.id)
        .and_return(staking_operation_model, staking_operation_model, updated_staking_operation_model)
    end

    context 'when the staking operation is completed' do
      it 'returns the completed StakingOperation' do
        expect(staking_operation.wait!.status).to eq('complete')
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

      expect(wallet_stake_api).to have_received(:broadcast_staking_operation).with(
        wallet_id,
        address_id,
        staking_operation.id,
        { signed_payload: hex_encoded_transaction, transaction_index: 0 }
      )
    end

    context 'with multiple transactions' do
      let(:other_hex_encoded_transaction) { '0xdeadbeef' }
      let(:other_transaction) { instance_double(Coinbase::Transaction) }
      let(:raw_tx) { instance_double(Eth::Tx::Eip1559) }

      before do
        allow(staking_operation).to receive(:transactions).and_return([transaction, other_transaction])
        allow(other_transaction).to receive_messages(signed?: transaction_signed, raw: raw_tx)
        allow(raw_tx).to receive(:hex).and_return(other_hex_encoded_transaction)
      end

      it 'broadcasts both transactions' do
        staking_operation.broadcast!

        expect(wallet_stake_api).to have_received(:broadcast_staking_operation).twice
      end

      it 'broadcasts the first transaction' do
        staking_operation.broadcast!

        expect(wallet_stake_api).to have_received(:broadcast_staking_operation).with(
          wallet_id,
          address_id,
          staking_operation.id,
          { signed_payload: hex_encoded_transaction, transaction_index: 0 }
        )
      end

      it 'broadcasts the second transaction' do
        staking_operation.broadcast!

        expect(wallet_stake_api).to have_received(:broadcast_staking_operation).with(
          wallet_id,
          address_id,
          staking_operation.id,
          { signed_payload: other_hex_encoded_transaction, transaction_index: 1 }
        )
      end
    end

    context 'when the transaction is not signed' do
      let(:transaction_signed) { false }

      it 'raises a transaction not signed exception' do
        expect { staking_operation.broadcast! }.to raise_error Coinbase::TransactionNotSignedError
      end
    end
  end

  describe '#terminal_state?' do
    subject { staking_operation.terminal_state? }

    context 'when status is complete' do
      before do
        allow(staking_operation_model).to receive(:status).and_return('complete')
      end

      it { is_expected.to be true }
    end

    context 'when status is failed' do
      before do
        allow(staking_operation_model).to receive(:status).and_return('failed')
      end

      it { is_expected.to be true }
    end

    context 'when status is not terminal' do
      before do
        allow(staking_operation_model).to receive(:status).and_return('initialized')
      end

      it { is_expected.to be false }
    end
  end

  describe '#failed_state?' do
    subject { staking_operation.failed_state? }

    context 'when status is failed' do
      before do
        allow(staking_operation_model).to receive(:status).and_return('failed')
      end

      it { is_expected.to be true }
    end

    context 'when status is not failed' do
      before do
        allow(staking_operation_model).to receive(:status).and_return('initialized')
      end

      it { is_expected.to be false }
    end
  end

  describe '#complete_state?' do
    subject { staking_operation.complete_state? }

    context 'when status is complete' do
      before do
        allow(staking_operation_model).to receive(:status).and_return('complete')
      end

      it { is_expected.to be true }
    end

    context 'when status is not complete' do
      before do
        allow(staking_operation_model).to receive(:status).and_return('initialized')
      end

      it { is_expected.to be false }
    end
  end

  describe '#to_s' do
    it 'returns the correct string representation of the staking operation' do
      expected_string = 'StakingOperation { id: some_id, status: initialized, network_id: ethereum_holesky, ' \
                        'address_id: address_id }'
      expect(staking_operation.to_s).to eq(expected_string)
    end
  end

  describe '#signed_voluntary_exit_messages' do
    context 'when metadata is nil' do
      let(:metadata) { nil }

      it 'returns an empty array' do
        expect(staking_operation.signed_voluntary_exit_messages).to eq([])
      end
    end

    context 'when metadata is present' do
      let(:encoded_message) { Base64.encode64('signed_message') }
      let(:metadata) do
        [instance_double(Coinbase::Client::SignedVoluntaryExitMessageMetadata, signed_voluntary_exit: encoded_message)]
      end

      it 'returns the decoded messages' do
        expect(staking_operation.signed_voluntary_exit_messages).to eq(['signed_message'])
      end
    end
  end
end
