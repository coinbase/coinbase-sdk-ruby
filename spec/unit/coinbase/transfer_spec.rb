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
  let(:model) do
    Coinbase::Client::Transfer.new({
                                     'network_id' => network_id,
                                     'wallet_id' => wallet_id,
                                     'address_id' => from_address_id,
                                     'destination' => to_address_id,
                                     'asset_id' => 'eth',
                                     'amount' => amount.to_s,
                                     'transfer_id' => transfer_id,
                                     'status' => 'pending',
                                     'unsigned_payload' => unsigned_payload
                                   })
  end
  let(:transfers_api) { double('Coinbase::Client::TransfersApi') }
  let(:client) { double('Jimson::Client') }

  before(:each) do
    configuration = double(Coinbase::Configuration)
    allow(Coinbase).to receive(:configuration).and_return(configuration)
    allow(configuration).to receive(:base_sepolia_client).and_return(client)
  end

  subject(:transfer) do
    described_class.new(model)
  end

  describe '#initialize' do
    it 'initializes a new Transfer' do
      expect(transfer).to be_a(Coinbase::Transfer)
    end
  end

  describe '#transfer_id' do
    it 'returns the transfer ID' do
      expect(transfer.transfer_id).to eq(transfer_id)
    end
  end

  describe '#unsigned_payload' do
    it 'returns the unsigned payload' do
      expect(transfer.unsigned_payload).to eq(unsigned_payload)
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
    it 'returns the amount' do
      expect(transfer.amount).to eq(eth_amount)
    end
  end

  describe '#asset_id' do
    it 'returns the asset ID' do
      expect(transfer.asset_id).to eq(:eth)
    end
  end

  describe '#destination_address_id' do
    it 'returns the destination address ID' do
      expect(transfer.destination_address_id).to eq(to_address_id)
    end
  end

  describe '#transaction' do
    it 'returns the Transfer transaction' do
      expect(transfer.transaction).to be_a(Eth::Tx::Eip1559)
      expect(transfer.transaction.amount).to eq(amount * Coinbase::WEI_PER_ETHER)
    end

    context 'when the transaction is for an ERC-20' do
      it 'returns the Transfer transaction' do
        # TODO: Implement this
      end
    end
  end

  describe '#transaction_hash' do
    context 'when the transaction has been signed' do
      it 'returns the transaction hash' do
        transfer.transaction.sign(from_key)
        expect(transfer.transaction_hash).to eq("0x#{transfer.transaction.hash}")
      end
    end

    context 'when the transaction has been created but not signed' do
      it 'returns nil' do
        transfer.transaction
        expect(transfer.transaction_hash).to be_nil
      end
    end

    context 'when the transaction has not been created' do
      it 'returns nil' do
        expect(transfer.transaction_hash).to be_nil
      end
    end
  end

  describe '#status' do
    context 'when the transaction has not been created' do
      it 'returns PENDING' do
        expect(transfer.status).to eq(Coinbase::Transfer::Status::PENDING)
      end
    end

    context 'when the transaction has been created but not signed' do
      it 'returns PENDING' do
        transfer.transaction
        expect(transfer.status).to eq(Coinbase::Transfer::Status::PENDING)
      end
    end

    context 'when the transaction has been signed but not broadcast' do
      before do
        transfer.transaction.sign(from_key)
        allow(client).to receive(:eth_getTransactionByHash).with(transfer.transaction_hash).and_return(nil)
      end

      it 'returns PENDING' do
        expect(transfer.status).to eq(Coinbase::Transfer::Status::PENDING)
      end
    end

    context 'when the transaction has been broadcast but not included in a block' do
      let(:onchain_transaction) { { 'blockHash' => nil } }

      before do
        transfer.transaction.sign(from_key)
        allow(client)
          .to receive(:eth_getTransactionByHash)
          .with(transfer.transaction_hash)
          .and_return(onchain_transaction)
      end

      it 'returns BROADCAST' do
        expect(transfer.status).to eq(Coinbase::Transfer::Status::BROADCAST)
      end
    end

    context 'when the transaction has confirmed' do
      let(:onchain_transaction) { { 'blockHash' => '0xdeadbeef' } }
      let(:transaction_receipt) { { 'status' => '0x1' } }

      before do
        transfer.transaction.sign(from_key)
        allow(client)
          .to receive(:eth_getTransactionByHash)
          .with(transfer.transaction_hash)
          .and_return(onchain_transaction)
        allow(client)
          .to receive(:eth_getTransactionReceipt)
          .with(transfer.transaction_hash)
          .and_return(transaction_receipt)
      end

      it 'returns COMPLETE' do
        expect(transfer.status).to eq(Coinbase::Transfer::Status::COMPLETE)
      end
    end

    context 'when the transaction has failed' do
      let(:onchain_transaction) { { 'blockHash' => '0xdeadbeef' } }
      let(:transaction_receipt) { { 'status' => '0x0' } }

      before do
        transfer.transaction.sign(from_key)
        allow(client)
          .to receive(:eth_getTransactionByHash)
          .with(transfer.transaction_hash)
          .and_return(onchain_transaction)
        allow(client)
          .to receive(:eth_getTransactionReceipt)
          .with(transfer.transaction_hash)
          .and_return(transaction_receipt)
      end

      it 'returns FAILED' do
        expect(transfer.status).to eq(Coinbase::Transfer::Status::FAILED)
      end
    end
  end

  describe '#wait!' do
    before do
      # TODO: This isn't working for some reason.
      allow(transfer).to receive(:sleep)
    end

    context 'when the transfer is completed' do
      let(:onchain_transaction) { { 'blockHash' => '0xdeadbeef' } }
      let(:transaction_receipt) { { 'status' => '0x1' } }

      before do
        transfer.transaction.sign(from_key)
        allow(client)
          .to receive(:eth_getTransactionByHash)
          .with(transfer.transaction_hash)
          .and_return(onchain_transaction)
        allow(client)
          .to receive(:eth_getTransactionReceipt)
          .with(transfer.transaction_hash)
          .and_return(transaction_receipt)
      end

      it 'returns the completed Transfer' do
        expect(transfer.wait!).to eq(transfer)
        expect(transfer.status).to eq(Coinbase::Transfer::Status::COMPLETE)
      end
    end

    context 'when the transfer is failed' do
      let(:onchain_transaction) { { 'blockHash' => '0xdeadbeef' } }
      let(:transaction_receipt) { { 'status' => '0x0' } }

      before do
        transfer.transaction.sign(from_key)
        allow(client)
          .to receive(:eth_getTransactionByHash)
          .with(transfer.transaction_hash)
          .and_return(onchain_transaction)
        allow(client)
          .to receive(:eth_getTransactionReceipt)
          .with(transfer.transaction_hash)
          .and_return(transaction_receipt)
      end

      it 'returns the failed Transfer' do
        expect(transfer.wait!).to eq(transfer)
        expect(transfer.status).to eq(Coinbase::Transfer::Status::FAILED)
      end
    end

    context 'when the transfer times out' do
      let(:onchain_transaction) { { 'blockHash' => nil } }

      before do
        transfer.transaction.sign(from_key)
        allow(client)
          .to receive(:eth_getTransactionByHash)
          .with(transfer.transaction_hash)
          .and_return(onchain_transaction)
      end

      it 'raises a Timeout::Error' do
        expect { transfer.wait!(0.2, 0.00001) }.to raise_error(Timeout::Error, 'Transfer timed out')
      end
    end
  end
end
