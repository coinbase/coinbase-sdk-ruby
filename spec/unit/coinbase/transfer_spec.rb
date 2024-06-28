# frozen_string_literal: true

describe Coinbase::Transfer do
  let(:from_key) { Eth::Key.new }
  let(:to_key) { Eth::Key.new }
  let(:network_id) { :base_sepolia }
  let(:wallet_id) { SecureRandom.uuid }
  let(:from_address_id) { from_key.address.to_s }
  let(:amount) { BigDecimal(100) }
  let(:to_address_id) { to_key.address.to_s }
  let(:transfer_id) { SecureRandom.uuid }
  let(:unsigned_payload) do \
    '7b2274797065223a22307832222c22636861696e4964223a2230783134613334222c226e6f6e63' \
'65223a22307830222c22746f223a22307834643965346633663464316138623566346637623166' \
'356235633762386436623262336231623062222c22676173223a22307835323038222c22676173' \
'5072696365223a6e756c6c2c226d61785072696f72697479466565506572476173223a223078' \
'3539363832663030222c226d6178466565506572476173223a2230783539363832663030222c22' \
'76616c7565223a2230783536626337356532643633313030303030222c22696e707574223a22' \
'3078222c226163636573734c697374223a5b5d2c2276223a22307830222c2272223a2230783022' \
'2c2273223a22307830222c2279506172697479223a22307830222c2268617368223a2230783664' \
'633334306534643663323633653363396561396135656438646561346332383966613861363966' \
'3031653635393462333732386230386138323335333433227d'
  end
  let(:signed_payload) do \
    '02f86b83014a3401830f4240830f4350825208946cd01c0f55ce9e0bf78f5e90f72b4345b' \
    '16d515d0280c001a0566afb8ab09129b3f5b666c3a1e4a7e92ae12bbee8c75b4c6e0c46f6' \
    '6dd10094a02115d1b52c49b39b6cb520077161c9bf636730b1b40e749250743f4524e9e4ba'
  end
  let(:transaction_hash) { '0x6c087c1676e8269dd81e0777244584d0cbfd39b6997b3477242a008fa9349e11' }
  let(:transaction_model) do
    Coinbase::Client::Transaction.new(
      status: 'pending',
      from_address_id: from_address_id,
      unsigned_payload: unsigned_payload
    )
  end
  let(:eth_asset) do
    Coinbase::Client::Asset.new(network_id: 'base-sepolia', asset_id: 'eth', decimals: 18)
  end
  let(:usdc_asset) do
    Coinbase::Client::Asset.new(network_id: 'base-sepolia', asset_id: 'usdc', decimals: 6)
  end
  let(:asset_model) { eth_asset }
  let(:eth_amount) { Coinbase::Asset.from_model(asset_model).from_atomic_amount(amount) }
  let(:model) do
    Coinbase::Client::Transfer.new(
      network_id: network_id,
      wallet_id: wallet_id,
      address_id: from_address_id,
      destination: to_address_id,
      amount: amount.to_s,
      asset_id: asset_model.asset_id,
      asset: asset_model,
      transfer_id: transfer_id,
      transaction: transaction_model
    )
  end
  let(:transfers_api) { double('Coinbase::Client::TransfersApi') }

  subject(:transfer) { described_class.new(model) }

  before do
    allow(Coinbase::Client::TransfersApi).to receive(:new).and_return(transfers_api)
  end

  describe '.create' do
    let(:asset_id) { :eth }
    let(:normalized_asset_id) { 'eth' }
    let(:asset) { Coinbase::Asset.from_model(eth_asset, asset_id: :eth) }
    let(:destination) { Coinbase::Destination.new(to_address_id, network_id: network_id) }
    let(:create_transfer_request) do
      {
        amount: amount.to_i.to_s,
        asset_id: normalized_asset_id,
        destination: to_address_id
      }
    end

    subject(:transfer) do
      described_class.create(
        address_id: from_address_id,
        asset_id: asset_id,
        amount: eth_amount,
        destination: destination,
        network_id: network_id,
        wallet_id: wallet_id
      )
    end

    before do
      allow(Coinbase::Asset)
        .to receive(:fetch)
        .with(network_id, asset.asset_id)
        .and_return(asset)

      allow(transfers_api)
        .to receive(:create_transfer)
        .with(wallet_id, from_address_id, create_transfer_request)
        .and_return(model)
    end

    it 'creates a new Transfer' do
      expect(transfer).to be_a(Coinbase::Transfer)
    end

    it 'sets the transfer properties' do
      expect(transfer.id).to eq(transfer_id)
    end

    context 'when the destination is not valid' do
      let(:destination) { asset }

      it 'raises an error' do
        expect { transfer }.to raise_error(ArgumentError)
      end
    end

    context 'when the asset is not the primary denomination' do
      let(:asset_id) { :wei }
      let(:asset) { Coinbase::Asset.from_model(eth_asset, asset_id: :wei) }
      let(:amount) { BigDecimal(100) }
      let(:eth_amount) { amount }

      it 'creates a new Transfer' do
        expect(transfer).to be_a(Coinbase::Transfer)
      end

      it 'constructs the transfer with the primary denomination from asset' do
        expect(transfer.asset_id).to be(:eth)
      end
    end
  end

  describe '.list' do
    let(:api) { transfers_api }
    let(:fetch_params) { ->(page) { [wallet_id, from_address_id, { limit: 100, page: page }] } }
    let(:resource_list_klass) { Coinbase::Client::TransferList }
    let(:item_klass) { Coinbase::Transfer }
    let(:item_initialize_args) { nil }
    let(:create_model) do
      ->(id) { Coinbase::Client::Transfer.new(transfer_id: id, network_id: 'base-sepolia') }
    end

    subject(:enumerator) do
      Coinbase::Transfer.list(wallet_id: wallet_id, address_id: from_address_id)
    end

    it_behaves_like 'it is a paginated enumerator', :transfers
  end

  describe '#initialize' do
    it 'initializes a new Transfer' do
      expect(transfer).to be_a(Coinbase::Transfer)
    end

    context 'when initialized with a model of a different type' do
      it 'raises an error' do
        expect do
          described_class.new(Coinbase::Client::Balance.new)
        end.to raise_error(RuntimeError)
      end
    end
  end

  describe '#id' do
    it 'returns the transfer ID' do
      expect(transfer.id).to eq(transfer_id)
    end
  end

  describe '#network_id' do
    it 'returns the network ID' do
      expect(transfer.network_id).to eq(network_id)
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
        expect(transfer.amount).to eq(eth_amount)
      end
    end

    context 'when the asset is something else' do
      let(:amount) { BigDecimal(100_000) }
      let(:decimals) { 3 }
      let(:asset_model) do
        Coinbase::Client::Asset.new(network_id: 'base-sepolia', asset_id: 'other', decimals: decimals)
      end

      it 'returns the amount in the whole units' do
        expect(transfer.amount).to eq(100)
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

    it 'configures the asset with the correct network ID' do
      expect(transfer.asset.network_id).to eq(network_id)
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
    let(:broadcasted_transaction_model) do
      Coinbase::Client::Transaction.new(
        status: 'broadcast',
        unsigned_payload: unsigned_payload,
        signed_payload: signed_payload
      )
    end
    let(:broadcasted_transfer_model) do
      instance_double(
        Coinbase::Client::Transfer,
        transaction: broadcasted_transaction_model,
        address_id: from_address_id
      )
    end

    subject(:broadcasted_transfer) { transfer.broadcast! }

    context 'when the transaction is signed' do
      let(:broadcast_transfer_request) do
        { signed_payload: transfer.transaction.raw.hex }
      end

      before do
        transfer.transaction.sign(from_key)

        allow(transfers_api)
          .to receive(:broadcast_transfer)
          .with(wallet_id, from_address_id, transfer_id, broadcast_transfer_request)
          .and_return(broadcasted_transfer_model)

        broadcasted_transfer
      end

      it 'returns the updated Transfer' do
        expect(broadcasted_transfer).to be_a(Coinbase::Transfer)
      end

      it 'broadcasts the transaction' do
        expect(transfers_api)
          .to have_received(:broadcast_transfer)
          .with(wallet_id, from_address_id, transfer_id, broadcast_transfer_request)
      end

      it 'updates the transaction status' do
        expect(broadcasted_transfer.transaction.status).to eq(Coinbase::Transaction::Status::BROADCAST)
      end

      it 'sets the transaction signed payload' do
        expect(broadcasted_transfer.transaction.signed_payload).to eq(signed_payload)
      end
    end

    context 'when the transaction is not signed' do
      it 'raises an error' do
        expect { broadcasted_transfer }.to raise_error(Coinbase::TransactionNotSignedError)
      end
    end
  end

  describe '#reload' do
    let(:updated_transaction_model) do
      Coinbase::Client::Transaction.new(
        status: 'complete',
        from_address_id: from_address_id,
        unsigned_payload: unsigned_payload
      )
    end

    let(:updated_amount) { BigDecimal(500_000_000) }
    let(:updated_eth_amount) do
      Coinbase::Asset.from_model(asset_model).from_atomic_amount(updated_amount)
    end

    let(:updated_model) do
      Coinbase::Client::Transfer.new(
        network_id: network_id,
        wallet_id: wallet_id,
        address_id: from_address_id,
        destination: to_address_id,
        asset_id: 'eth',
        asset: eth_asset,
        amount: updated_amount.to_s,
        transfer_id: transfer_id,
        transaction: updated_transaction_model
      )
    end

    before do
      allow(transfers_api)
        .to receive(:get_transfer)
        .with(transfer.wallet_id, transfer.from_address_id, transfer.id)
        .and_return(updated_model)
    end

    it 'updates the transfer transaction' do
      expect(transfer.transaction.status).to eq(Coinbase::Transaction::Status::PENDING)
      expect(transfer.reload.transaction.status).to eq(Coinbase::Transaction::Status::COMPLETE)
    end

    it 'updates properties on the transfer' do
      expect(transfer.amount).to eq(eth_amount)
      expect(transfer.reload.amount).to eq(updated_eth_amount)
    end
  end

  describe '#wait!' do
    let(:updated_model) do
      Coinbase::Client::Transfer.new(
        network_id: network_id,
        wallet_id: wallet_id,
        address_id: from_address_id,
        destination: to_address_id,
        amount: amount.to_s,
        asset_id: asset_model.asset_id,
        asset: asset_model,
        transfer_id: transfer_id,
        transaction: updated_transaction_model
      )
    end

    before do
      # TODO: This isn't working for some reason.
      allow(transfer).to receive(:sleep)

      allow(transfers_api)
        .to receive(:get_transfer)
        .with(transfer.wallet_id, transfer.from_address_id, transfer.id)
        .and_return(model, model, updated_model)
    end

    context 'when the transfer is completed' do
      let(:updated_transaction_model) do
        Coinbase::Client::Transaction.new(
          status: 'complete',
          from_address_id: from_address_id,
          unsigned_payload: unsigned_payload
        )
      end

      it 'returns the completed Transfer' do
        expect(transfer.wait!).to eq(transfer)
        expect(transfer.status).to eq(Coinbase::Transaction::Status::COMPLETE)
      end
    end

    context 'when the transfer is failed' do
      let(:updated_transaction_model) do
        Coinbase::Client::Transaction.new(
          status: 'failed',
          from_address_id: from_address_id,
          unsigned_payload: unsigned_payload
        )
      end

      it 'returns the failed Transfer' do
        expect(transfer.wait!).to eq(transfer)
        expect(transfer.status).to eq(Coinbase::Transaction::Status::FAILED)
      end
    end

    context 'when the transfer times out' do
      let(:updated_transaction_model) do
        Coinbase::Client::Transaction.new(
          status: 'pending',
          from_address_id: from_address_id,
          unsigned_payload: unsigned_payload
        )
      end

      it 'raises a Timeout::Error' do
        expect { transfer.wait!(0.2, 0.00001) }.to raise_error(Timeout::Error, 'Transfer timed out')
      end
    end
  end

  describe '#inspect' do
    it 'includes transfer details' do
      expect(transfer.inspect).to include(
        transfer_id,
        Coinbase.to_sym(network_id).to_s,
        from_address_id,
        to_address_id,
        eth_amount.to_s,
        transfer.asset_id.to_s,
        transfer.status.to_s
      )
    end

    it 'returns the same value as to_s' do
      expect(transfer.inspect).to eq(transfer.to_s)
    end

    context 'when the transfer has been broadcast on chain' do
      let(:transaction_model) do
        Coinbase::Client::Transaction.new(
          status: 'broadcast',
          from_address_id: from_address_id,
          unsigned_payload: unsigned_payload,
          signed_payload: signed_payload,
          transaction_hash: transaction_hash
        )
      end

      it 'includes the updated status' do
        expect(transfer.inspect).to include('broadcast')
      end
    end
  end
end
