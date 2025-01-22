# frozen_string_literal: true

describe Coinbase::Transfer do
  subject(:transfer) { described_class.new(model) }

  let(:from_key) { build(:key) }
  let(:to_key) { Eth::Key.new }
  let(:network_id) { :base_sepolia }
  let(:normalized_network_id) { 'base-sepolia' }
  let(:network) { build(:network, network_id) }
  let(:from_address_id) { from_key.address.to_s }
  let(:to_address_id) { to_key.address.to_s }
  let(:transaction_model) { build(:transaction_model, key: from_key) }
  let(:usdc_asset) { build(:asset_model, :usdc) }
  let(:asset_model) { eth_asset }
  let(:whole_amount) { 123 }
  let(:atomic_amount) { build(:asset, :eth).to_atomic_amount(whole_amount) }
  let(:model) do
    build(:transfer_model, network_id, key: from_key, to_key: to_key, whole_amount: whole_amount)
  end
  let(:wallet_id) { model.wallet_id }
  let(:transfers_api) { instance_double(Coinbase::Client::TransfersApi) }

  before do
    allow(Coinbase::Client::TransfersApi).to receive(:new).and_return(transfers_api)

    allow(Coinbase::Network)
      .to receive(:from_id)
      .with(satisfy { |n| n == network || n == network_id || n == normalized_network_id })
      .and_return(network)
  end

  describe '.create' do
    subject(:transfer) do
      described_class.create(
        address_id: from_address_id,
        asset_id: asset_id,
        amount: whole_amount,
        destination: destination,
        network: network_id,
        wallet_id: wallet_id
      )
    end

    let(:asset_id) { :eth }
    let(:normalized_asset_id) { 'eth' }
    let(:asset) { build(:asset, :eth) }
    let(:destination) { Coinbase::Destination.new(to_address_id, network: network_id) }
    let(:create_transfer_request) do
      {
        amount: atomic_amount.to_i.to_s,
        asset_id: normalized_asset_id,
        destination: to_address_id,
        network_id: normalized_network_id,
        gasless: false,
        skip_batching: false
      }
    end

    before do
      allow(network)
        .to receive(:get_asset)
        .with(asset.asset_id)
        .and_return(asset)

      allow(transfers_api)
        .to receive(:create_transfer)
        .with(wallet_id, from_address_id, create_transfer_request)
        .and_return(model)
    end

    it 'creates a new Transfer' do
      expect(transfer).to be_a(described_class)
    end

    it 'sets the transfer properties' do
      expect(transfer.id).to eq(model.transfer_id)
    end

    context 'when skip_batching is true and gasless is false' do
      subject(:transfer) do
        described_class.create(
          address_id: from_address_id,
          asset_id: asset_id,
          amount: whole_amount,
          destination: destination,
          network: network_id,
          wallet_id: wallet_id,
          gasless: false,
          skip_batching: true
        )
      end

      it 'raises an error' do
        expect { transfer }.to raise_error(ArgumentError, /Cannot skip batching without gasless option set to true/)
      end
    end

    context 'when the destination is not valid' do
      let(:destination) { asset }

      it 'raises an error' do
        expect { transfer }.to raise_error(ArgumentError)
      end
    end

    context 'when the asset is not the primary denomination' do
      let(:asset_id) { :wei }
      let(:asset) { build(:asset, asset_id) }
      let(:whole_amount) { BigDecimal(100) }
      # The atomic amount is the same as the whole amount for wei
      let(:atomic_amount) { BigDecimal(100) }

      it 'creates a new Transfer' do
        expect(transfer).to be_a(described_class)
      end

      it 'constructs the transfer with the primary denomination from asset' do
        expect(transfer.asset_id).to be(:eth)
      end
    end

    context 'when the transfer is gasless' do
      subject(:transfer) do
        described_class.create(
          address_id: from_address_id,
          asset_id: asset_id,
          amount: whole_amount,
          destination: destination,
          network: network_id,
          wallet_id: wallet_id,
          gasless: true
        )
      end

      let(:create_transfer_request) do
        {
          amount: atomic_amount.to_i.to_s,
          asset_id: normalized_asset_id,
          destination: to_address_id,
          network_id: normalized_network_id,
          gasless: true,
          skip_batching: false
        }
      end

      it 'creates a new Transfer' do
        expect(transfer).to be_a(described_class)
      end

      it 'sets the transfer properties' do
        expect(transfer.id).to eq(model.transfer_id)
      end
    end
  end

  describe '.list' do
    subject(:enumerator) do
      described_class.list(wallet_id: wallet_id, address_id: from_address_id)
    end

    let(:api) { transfers_api }
    let(:fetch_params) { ->(page) { [wallet_id, from_address_id, { limit: 100, page: page }] } }
    let(:resource_list_klass) { Coinbase::Client::TransferList }
    let(:item_klass) { described_class }
    let(:item_initialize_args) { nil }
    let(:create_model) do
      ->(id) { build(:transfer_model, network_id, transfer_id: id) }
    end

    it_behaves_like 'it is a paginated enumerator', :transfers
  end

  describe '#initialize' do
    it 'initializes a new Transfer' do
      expect(transfer).to be_a(described_class)
    end

    context 'when initialized with a model of a different type' do
      it 'raises an error' do
        expect do
          described_class.new(build(:balance_model, network_id))
        end.to raise_error(RuntimeError)
      end
    end
  end

  describe '#id' do
    it 'returns the transfer ID' do
      expect(transfer.id).to eq(model.transfer_id)
    end
  end

  describe '#network' do
    it 'returns the network' do
      expect(transfer.network).to eq(network)
    end
  end

  describe '#wallet_id' do
    it 'returns the wallet ID' do
      expect(transfer.wallet_id).to eq(wallet_id)
    end
  end

  describe '#from_address_id' do
    it 'returns the source address ID' do
      expect(transfer.from_address_id).to eq(from_address_id)
    end
  end

  describe '#amount' do
    context 'when the from asset is :eth' do
      it 'returns the amount in whole ETH units' do
        expect(transfer.amount).to eq(whole_amount)
      end
    end

    context 'when the asset is something else' do
      let(:asset) { build(:asset, network_id, :usdc) }
      let(:amount) { BigDecimal(100_000) }
      let(:model) { build(:transfer_model, network_id, :usdc, :completed, amount: amount) }

      it 'returns the amount in the whole units' do
        expect(transfer.amount).to eq(asset.from_atomic_amount(amount))
      end
    end
  end

  describe '#asset_id' do
    it 'returns the asset ID' do
      expect(transfer.asset_id).to eq(:eth)
    end
  end

  describe '#asset' do
    it 'returns the Asset' do
      expect(transfer.asset).to be_a(Coinbase::Asset)
    end

    it 'configures the asset with the correct network' do
      expect(transfer.asset.network).to eq(network)
    end

    it 'configures the asset with the correct asset ID' do
      expect(transfer.asset.asset_id).to eq(:eth)
    end

    it 'configures the asset with the correct decimals' do
      expect(transfer.asset.decimals).to eq(18)
    end
  end

  describe '#destination_address_id' do
    it 'returns the destination address ID' do
      expect(transfer.destination_address_id).to eq(to_address_id)
    end
  end

  describe '#transaction' do
    it 'returns the Transaction' do
      expect(transfer.transaction).to be_a(Coinbase::Transaction)
    end
  end

  describe '#broadcast!' do
    subject(:broadcasted_transfer) { transfer.broadcast! }

    let(:broadcasted_transfer_model) { build(:transfer_model, network_id, :broadcasted, key: from_key) }

    context 'when the transaction is signed' do
      let(:broadcast_transfer_request) do
        { signed_payload: transfer.transaction.raw.hex }
      end

      before do
        transfer.transaction.sign(from_key)

        allow(transfers_api)
          .to receive(:broadcast_transfer)
          .with(wallet_id, from_address_id, model.transfer_id, broadcast_transfer_request)
          .and_return(broadcasted_transfer_model)

        broadcasted_transfer
      end

      it 'returns the updated Transfer' do
        expect(broadcasted_transfer).to be_a(described_class)
      end

      it 'broadcasts the transaction' do
        expect(transfers_api)
          .to have_received(:broadcast_transfer)
          .with(wallet_id, from_address_id, model.transfer_id, broadcast_transfer_request)
      end

      it 'updates the transaction status' do
        expect(broadcasted_transfer.transaction.status).to eq(Coinbase::Transaction::Status::BROADCAST)
      end

      it 'sets the transaction signed payload' do
        expect(broadcasted_transfer.transaction.signed_payload)
          .to eq(broadcasted_transfer_model.transaction.signed_payload)
      end
    end

    context 'when the transaction is not signed' do
      it 'raises an error' do
        expect { broadcasted_transfer }.to raise_error(Coinbase::TransactionNotSignedError)
      end
    end

    context 'when the transfer is gasless' do
      let(:model) do
        build(:transfer_model, network_id, :pending, :gasless)
      end

      let(:broadcasted_transfer_model) do
        build(:transfer_model, network_id, :signed, :gasless)
      end

      context 'when the transaction is signed' do
        let(:sponsored_send_model) { build(:sponsored_send_model, :signed) }
        let(:broadcast_transfer_request) do
          { signed_payload: transfer.sponsored_send.signature }
        end

        before do
          transfer.sign(from_key)

          allow(transfers_api)
            .to receive(:broadcast_transfer)
            .with(wallet_id, from_address_id, model.transfer_id, broadcast_transfer_request)
            .and_return(broadcasted_transfer_model)

          broadcasted_transfer
        end

        it 'returns the updated Transfer' do
          expect(broadcasted_transfer).to be_a(described_class)
        end

        it 'broadcasts the transaction' do
          expect(transfers_api)
            .to have_received(:broadcast_transfer)
            .with(wallet_id, from_address_id, model.transfer_id, broadcast_transfer_request)
        end

        it 'updates the sponsored send status' do
          expect(broadcasted_transfer.sponsored_send.status)
            .to eq(Coinbase::Transaction::Status::SIGNED)
        end

        it 'sets the transaction signed payload' do
          expect(broadcasted_transfer.sponsored_send.signature)
            .to eq(sponsored_send_model.signature)
        end
      end
    end
  end

  describe '#reload' do
    let(:updated_amount) { BigDecimal(500_000_000) }
    let(:updated_eth_amount) { build(:asset, :eth).from_atomic_amount(updated_amount) }
    let(:updated_model) { build(:transfer_model, network_id, :completed, amount: updated_amount) }

    before do
      allow(transfers_api)
        .to receive(:get_transfer)
        .with(transfer.wallet_id, transfer.from_address_id, transfer.id)
        .and_return(updated_model)
    end

    it 'updates the transfer transaction' do
      expect(transfer.reload.transaction.status).to eq(Coinbase::Transaction::Status::COMPLETE)
    end

    it 'updates properties on the transfer' do
      expect(transfer.reload.amount).to eq(updated_eth_amount)
    end
  end

  describe '#wait!' do
    before do
      allow(transfer).to receive(:sleep) # rubocop:disable RSpec/SubjectStub

      allow(transfers_api)
        .to receive(:get_transfer)
        .with(transfer.wallet_id, transfer.from_address_id, transfer.id)
        .and_return(model, model, updated_model)
    end

    context 'when the transfer is completed' do
      let(:updated_model) { build(:transfer_model, network_id, :completed) }

      it 'returns the completed Transfer' do
        expect(transfer.wait!.status).to eq(Coinbase::Transaction::Status::COMPLETE)
      end
    end

    context 'when the transfer is failed' do
      let(:updated_model) { build(:transfer_model, network_id, :failed) }

      it 'returns the failed Transfer' do
        expect(transfer.wait!.status).to eq(Coinbase::Transaction::Status::FAILED)
      end
    end

    context 'when the transfer times out' do
      let(:updated_model) { build(:transfer_model, network_id, :pending) }

      it 'raises a Timeout::Error' do
        expect { transfer.wait!(0.2, 0.00001) }.to raise_error(Timeout::Error, 'Transfer timed out')
      end
    end
  end

  describe '#inspect' do
    it 'includes transfer details' do
      expect(transfer.inspect).to include(
        model.transfer_id,
        Coinbase.to_sym(network_id).to_s,
        from_address_id,
        to_address_id,
        whole_amount.to_s,
        transfer.asset_id.to_s,
        transfer.status.to_s
      )
    end

    it 'returns the same value as to_s' do
      expect(transfer.inspect).to eq(transfer.to_s)
    end

    context 'when the transfer has been broadcast on chain' do
      let(:model) { build(:transfer_model, network_id, :broadcasted) }

      it 'includes the updated status' do
        expect(transfer.inspect).to include('broadcast')
      end
    end
  end
end
