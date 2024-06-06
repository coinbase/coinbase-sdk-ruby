# frozen_string_literal: true

describe Coinbase::Transfer do
  let(:from_key) { Eth::Key.new }
  let(:to_key) { Eth::Key.new }
  let(:network_id) { :base_sepolia }
  let(:wallet_id) { SecureRandom.uuid }
  let(:from_address_id) { from_key.address.to_s }
  let(:amount) { BigDecimal(100) }
  let(:eth_amount) { amount / BigDecimal(Coinbase::WEI_PER_ETHER.to_s) }
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
  let(:asset) { eth_asset }
  let(:model) do
    Coinbase::Client::Transfer.new(
      network_id: network_id,
      wallet_id: wallet_id,
      address_id: from_address_id,
      destination: to_address_id,
      amount: amount.to_s,
      asset_id: asset.asset_id,
      asset: asset,
      transfer_id: transfer_id,
      transaction: transaction_model
    )
  end
  let(:transfers_api) { double('Coinbase::Client::TransfersApi') }
  let(:client) { double('Jimson::Client') }

  subject(:transfer) { described_class.new(model) }

  before do
    allow(Coinbase::Client::TransfersApi).to receive(:new).and_return(transfers_api)
  end

  describe '#initialize' do
    it 'initializes a new Transfer' do
      expect(transfer).to be_a(Coinbase::Transfer)
    end

    context 'when initialized with a model of a different type' do
      it 'raises an error' do
        expect do
          described_class.new(Coinbase::Client::Balance.new)
        end.to raise_error
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
      let(:asset) do
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

  describe '#reload' do
    let(:updated_transaction_model) do
      Coinbase::Client::Transaction.new(
        status: 'complete',
        from_address_id: from_address_id,
        unsigned_payload: unsigned_payload
      )
    end

    let(:updated_amount) { BigDecimal(500_000_000) }
    let(:updated_eth_amount) { updated_amount / BigDecimal(Coinbase::WEI_PER_ETHER.to_s) }

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
        asset_id: asset.asset_id,
        asset: asset,
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
