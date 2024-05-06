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
  let(:usdc_model) do
    Coinbase::Client::Transfer.new({
                                     'network_id' => network_id,
                                     'wallet_id' => wallet_id,
                                     'address_id' => from_address_id,
                                     'destination' => to_address_id,
                                     'asset_id' => 'usdc',
                                     'amount' => amount.to_s,
                                     'transfer_id' => transfer_id,
                                     'status' => 'pending',
                                     'unsigned_payload' => unsigned_payload
                                   })
  end
  let(:broadcast_model) do
    Coinbase::Client::Transfer.new({
                                     'network_id' => network_id,
                                     'wallet_id' => wallet_id,
                                     'address_id' => from_address_id,
                                     'destination' => to_address_id,
                                     'asset_id' => 'eth',
                                     'amount' => amount.to_s,
                                     'transfer_id' => transfer_id,
                                     'status' => 'pending',
                                     'unsigned_payload' => unsigned_payload,
                                     'signed_payload' => signed_payload,
                                     'transaction_hash' => transaction_hash
                                   })
  end
  let(:transfers_api) { double('Coinbase::Client::TransfersApi') }
  let(:client) { double('Jimson::Client') }

  before(:each) do
    allow(Coinbase.configuration).to receive(:base_sepolia_client).and_return(client)
    allow(Coinbase::Client::TransfersApi).to receive(:new).and_return(transfers_api)
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
    context 'when the asset ID is :eth' do
      it 'returns the amount' do
        expect(transfer.amount).to eq(eth_amount)
      end
    end
    context 'when the asset ID is :usdc' do
      subject(:transfer) do
        described_class.new(usdc_model)
      end

      it 'returns the amount' do
        expect(transfer.amount).to eq(amount)
      end
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

  describe '#signed_payload' do
    context 'when the transfer has not been broadcast on chain' do
      it 'returns nil' do
        expect(transfer.signed_payload).to be_nil
      end
    end
    context 'when the transfer has been broadcast on chain' do
      subject(:transfer) do
        described_class.new(broadcast_model)
      end

      it 'returns the signed payload' do
        expect(transfer.signed_payload).to eq(signed_payload)
      end
    end
  end

  describe '#transaction_hash' do
    context 'when the transfer has not been broadcast on chain' do
      it 'returns nil' do
        expect(transfer.transaction_hash).to be_nil
      end
    end
    context 'when the transfer has been broadcast on chain' do
      subject(:transfer) do
        described_class.new(broadcast_model)
      end

      it 'returns the transaction hash' do
        expect(transfer.transaction_hash).to eq(transaction_hash)
      end
    end
  end

  describe '#transaction' do
    it 'returns the Transfer transaction' do
      expect(transfer.transaction).to be_a(Eth::Tx::Eip1559)
      expect(transfer.transaction.amount).to eq(amount * Coinbase::WEI_PER_ETHER)
    end

    context 'when the transaction is for an ERC-20' do
      let(:usdc_unsigned_payload) do
        '7b2274797065223a22307832222c22636861696e4964223a2230783134613334222c226e6f6e6365223a22307830222c22746f223a22' \
        '307830333663626435333834326335343236363334653739323935343165633233313866336463663765222c22676173223a22307831' \
        '38366130222c226761735072696365223a6e756c6c2c226d61785072696f72697479466565506572476173223a223078353936383266' \
        '3030222c226d6178466565506572476173223a2230783539363832663030222c2276616c7565223a22307830222c22696e707574223a' \
        '223078613930353963626230303030303030303030303030303030303030303030303034643965346633663464316138623566346637' \
        '623166356235633762386436623262336231623062303030303030303030303030303030303030303030303030303030303030303030' \
        '30303030303030303030303030303030303030303030303030303030303031222c226163636573734c697374223a5b5d2c2276223a22' \
        '307830222c2272223a22307830222c2273223a22307830222c2279506172697479223a22307830222c2268617368223a223078316365' \
        '386164393935306539323437316461666665616664653562353836373938323430663630303138336136363365393661643738383039' \
        '66643965303666227d'
      end

      let(:usdc_model) do
        Coinbase::Client::Transfer.new({
                                         'address_id' => from_address_id,
                                         'destination' => to_address_id,
                                         'unsigned_payload' => usdc_unsigned_payload
                                       })
      end
      let(:usdc_transfer) do
        described_class.new(usdc_model)
      end

      it 'returns the Transfer transaction' do
        expect(usdc_transfer.transaction).to be_a(Eth::Tx::Eip1559)
        expect(usdc_transfer.transaction.amount).to eq(BigDecimal('0'))
        expect(usdc_transfer.transaction.chain_id).to eq(84_532)
        expect(usdc_transfer.transaction.max_fee_per_gas).to eq(1_500_000_000)
        expect(usdc_transfer.transaction.max_priority_fee_per_gas).to eq(1_500_000_000)
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
      end

      it 'returns PENDING' do
        expect(transfer.status).to eq(Coinbase::Transfer::Status::PENDING)
      end
    end

    context 'when the transaction has been broadcast but not included in a block' do
      let(:onchain_transaction) { { 'blockHash' => nil } }
      subject(:transfer) do
        described_class.new(broadcast_model)
      end

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
      subject(:transfer) do
        described_class.new(broadcast_model)
      end

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
      subject(:transfer) do
        described_class.new(broadcast_model)
      end

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
    subject(:transfer) do
      described_class.new(broadcast_model)
    end

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
