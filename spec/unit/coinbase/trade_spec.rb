# frozen_string_literal: true

describe Coinbase::Trade do
  let(:from_key) { Eth::Key.new }
  let(:network_id) { :base_sepolia }
  let(:wallet_id) { SecureRandom.uuid }
  let(:address_id) { from_key.address.to_s }
  let(:from_amount) { BigDecimal(100) }
  let(:to_amount) { BigDecimal(100_000) }
  let(:eth_amount) { Coinbase::Asset.from_model(eth_asset).from_atomic_amount(from_amount) }
  let(:usdc_amount) { Coinbase::Asset.from_model(usdc_asset).from_atomic_amount(to_amount) }
  let(:trade_id) { SecureRandom.uuid }
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
  let(:eth_asset) { build(:asset_model) }
  let(:usdc_asset) { build(:asset_model, :usdc) }
  let(:transaction_model) do
    Coinbase::Client::Transaction.new(
      status: 'pending',
      from_address_id: address_id,
      unsigned_payload: unsigned_payload
    )
  end
  let(:approve_transaction_model) { nil }
  let(:from_asset_model) { eth_asset }
  let(:from_asset) { Coinbase::Asset.from_model(from_asset_model) }
  let(:to_asset_model) { usdc_asset }
  let(:to_asset) { Coinbase::Asset.from_model(to_asset_model) }
  let(:model) do
    Coinbase::Client::Trade.new(
      network_id: network_id,
      wallet_id: wallet_id,
      address_id: address_id,
      from_asset: from_asset_model,
      to_asset: to_asset_model,
      from_amount: from_amount.to_s,
      to_amount: to_amount.to_s,
      trade_id: trade_id,
      transaction: transaction_model,
      approve_transaction: approve_transaction_model
    )
  end
  let(:trades_api) { double('Coinbase::Client::TradesApi') }

  before do
    allow(Coinbase::Client::TradesApi).to receive(:new).and_return(trades_api)
  end

  subject(:trade) do
    described_class.new(model)
  end

  describe '.create' do
    let(:from_asset_id) { :eth }
    let(:normalized_from_asset_id) { 'eth' }
    let(:to_asset_id) { :usdc }
    let(:normalized_to_asset_id) { 'usdc' }

    let(:create_trade_request) do
      {
        amount: from_amount.to_i.to_s,
        from_asset_id: normalized_from_asset_id,
        to_asset_id: normalized_to_asset_id
      }
    end

    subject(:trade) do
      described_class.create(
        address_id: address_id,
        from_asset_id: from_asset_id,
        to_asset_id: to_asset_id,
        amount: eth_amount,
        network_id: network_id,
        wallet_id: wallet_id
      )
    end

    before do
      allow(Coinbase::Asset).to receive(:fetch).with(network_id, from_asset.asset_id).and_return(from_asset)
      allow(Coinbase::Asset).to receive(:fetch).with(network_id, to_asset.asset_id).and_return(to_asset)

      allow(trades_api)
        .to receive(:create_trade)
        .with(wallet_id, address_id, create_trade_request)
        .and_return(model)
    end

    it 'creates a new Trade' do
      expect(trade).to be_a(Coinbase::Trade)
    end

    it 'sets the trade properties' do
      expect(trade.id).to eq(trade_id)
    end

    context 'when the from asset is not the primary denomination' do
      let(:from_asset_id) { :wei }
      let(:from_asset) { Coinbase::Asset.from_model(eth_asset, asset_id: :wei) }
      let(:from_amount) { BigDecimal(100) }
      let(:eth_amount) { from_amount }

      it 'creates a new Trade' do
        expect(trade).to be_a(Coinbase::Trade)
      end

      it 'constructs the trade with the primary denomination from asset' do
        expect(trade.from_asset_id).to be(:eth)
      end
    end

    context 'when the to asset is not the primary denomination' do
      let(:to_asset_id) { :gwei }
      let(:to_asset) { Coinbase::Asset.from_model(eth_asset, asset_id: :gwei) }
      let(:to_asset_model) { eth_asset }
      let(:normalized_to_asset_id) { 'eth' }

      it 'creates a new Trade' do
        expect(trade).to be_a(Coinbase::Trade)
      end

      it 'constructs the trade with the primary denomination to asset' do
        expect(trade.to_asset_id).to be(:eth)
      end
    end
  end

  describe '.list' do
    let(:api) { trades_api }
    let(:fetch_params) { ->(page) { [wallet_id, address_id, { limit: 100, page: page }] } }
    let(:resource_list_klass) { Coinbase::Client::TradeList }
    let(:item_klass) { Coinbase::Trade }
    let(:item_initialize_args) { nil }
    let(:create_model) do
      ->(id) { Coinbase::Client::Trade.new(trade_id: id, network_id: 'base-sepolia') }
    end

    subject(:enumerator) do
      Coinbase::Trade.list(wallet_id: wallet_id, address_id: address_id)
    end

    it_behaves_like 'it is a paginated enumerator', :trades
  end

  describe '#initialize' do
    it 'initializes a new Trade' do
      expect(trade).to be_a(Coinbase::Trade)
    end

    context 'when initialized with a model of a different type' do
      it 'raises an error' do
        expect do
          described_class.new(Coinbase::Client::Balance.new)
        end.to raise_error(StandardError)
      end
    end
  end

  describe '#id' do
    it 'returns the trade ID' do
      expect(trade.id).to eq(trade_id)
    end
  end

  describe '#network_id' do
    it 'returns the network ID' do
      expect(trade.network_id).to eq(network_id)
    end
  end

  describe '#wallet_id' do
    it 'returns the wallet ID' do
      expect(trade.wallet_id).to eq(wallet_id)
    end
  end

  describe '#address_id' do
    it 'returns the address ID' do
      expect(trade.address_id).to eq(address_id)
    end
  end

  describe '#from_amount' do
    context 'when the from asset is :eth' do
      it 'returns the amount in whole ETH units' do
        expect(trade.from_amount).to eq(eth_amount)
      end
    end

    context 'when the from asset is something else' do
      let(:from_amount) { BigDecimal(100_000) }
      let(:decimals) { 3 }
      let(:from_asset_model) { build(:asset_model, asset_id: 'other', decimals: decimals) }

      it 'returns the from amount in the whole units' do
        expect(trade.from_amount).to eq(100)
      end
    end
  end

  describe '#from_asset_id' do
    it 'returns the from asset ID' do
      expect(trade.from_asset_id).to eq(:eth)
    end
  end

  describe '#to_amount' do
    context 'when the to asset is :usdc' do
      it 'returns the amount' do
        expect(trade.to_amount).to eq(usdc_amount)
      end
    end

    context 'when the to asset is something else' do
      let(:to_amount) { BigDecimal(42_000_000) }
      let(:decimals) { 6 }
      let(:to_asset_model) { build(:asset_model, asset_id: 'other', decimals: decimals) }

      it 'returns the to amount in the whole units' do
        expect(trade.to_amount).to eq(BigDecimal(42))
      end
    end
  end

  describe '#to_asset_id' do
    it 'returns the to asset ID' do
      expect(trade.to_asset_id).to eq(:usdc)
    end
  end

  describe '#transactions' do
    it 'returns a list containing the trade transaction' do
      expect(trade.transactions).to contain_exactly(trade.transaction)
    end

    context 'when there is an approve transaction' do
      let(:approve_transaction_model) do
        Coinbase::Client::Transaction.new(
          status: 'pending',
          from_address_id: address_id,
          unsigned_payload: unsigned_payload
        )
      end

      it 'returns a list containing both transactions' do
        expect(trade.transactions).to contain_exactly(trade.transaction, trade.approve_transaction)
      end
    end
  end

  describe '#transaction' do
    it 'returns the Transaction' do
      expect(trade.transaction).to be_a(Coinbase::Transaction)
    end

    it 'sets the from_address_id' do
      expect(trade.transaction.from_address_id).to eq(address_id)
    end
  end

  describe '#status' do
    it 'returns the transaction status' do
      expect(trade.status).to eq(Coinbase::Transaction::Status::PENDING)
    end
  end

  describe '#broadcast!' do
    let(:broadcasted_approve_transaction_model) { nil }
    let(:broadcasted_transaction_model) do
      Coinbase::Client::Transaction.new(
        status: 'broadcast',
        unsigned_payload: unsigned_payload,
        signed_payload: signed_payload
      )
    end
    let(:broadcasted_trade_model) do
      instance_double(
        Coinbase::Client::Trade,
        transaction: broadcasted_transaction_model,
        approve_transaction: broadcasted_approve_transaction_model,
        address_id: address_id
      )
    end

    subject(:broadcasted_trade) { trade.broadcast! }

    context 'when the transaction is signed' do
      let(:broadcast_trade_request) do
        { signed_payload: trade.transaction.raw.hex }
      end

      before do
        trade.transaction.sign(from_key)

        allow(trades_api)
          .to receive(:broadcast_trade)
          .with(wallet_id, address_id, trade_id, broadcast_trade_request)
          .and_return(broadcasted_trade_model)

        broadcasted_trade
      end

      it 'returns the updated Trade' do
        expect(broadcasted_trade).to be_a(Coinbase::Trade)
      end

      it 'broadcasts the transaction' do
        expect(trades_api)
          .to have_received(:broadcast_trade)
          .with(wallet_id, address_id, trade_id, broadcast_trade_request)
      end

      it 'updates the transaction status' do
        expect(broadcasted_trade.transaction.status).to eq(Coinbase::Transaction::Status::BROADCAST)
      end

      it 'sets the transaction signed payload' do
        expect(broadcasted_trade.transaction.signed_payload).to eq(signed_payload)
      end
    end

    context 'when the transaction is not signed' do
      it 'raises an error' do
        expect { broadcasted_trade }.to raise_error(Coinbase::TransactionNotSignedError)
      end
    end

    context 'when there is an approve transaction' do
      let(:approve_transaction_model) do
        Coinbase::Client::Transaction.new(
          status: 'pending',
          from_address_id: address_id,
          unsigned_payload: unsigned_payload
        )
      end
      let(:broadcasted_approve_transaction_model) do
        Coinbase::Client::Transaction.new(
          status: 'broadcast',
          from_address_id: address_id,
          unsigned_payload: unsigned_payload,
          signed_payload: signed_payload
        )
      end

      context 'and both transactions are signed' do
        let(:broadcast_trade_request) do
          {
            signed_payload: trade.transaction.raw.hex,
            approve_transaction_signed_payload: trade.approve_transaction.raw.hex
          }
        end

        before do
          trade.transaction.sign(from_key)
          trade.approve_transaction.sign(from_key)

          allow(trades_api)
            .to receive(:broadcast_trade)
            .with(wallet_id, address_id, trade_id, broadcast_trade_request)
            .and_return(broadcasted_trade_model)

          broadcasted_trade
        end

        it 'returns the updated Trade' do
          expect(broadcasted_trade).to be_a(Coinbase::Trade)
        end

        it 'broadcasts the transaction with both signed payloads' do
          expect(trades_api)
            .to have_received(:broadcast_trade)
            .with(wallet_id, address_id, trade_id, broadcast_trade_request)
        end

        it 'updates the transaction status' do
          expect(broadcasted_trade.transaction.status).to eq(Coinbase::Transaction::Status::BROADCAST)
        end

        it 'sets the transaction signed payload' do
          expect(broadcasted_trade.transaction.signed_payload).to eq(signed_payload)
        end

        it 'updates the approve transaction status' do
          expect(broadcasted_trade.transaction.status).to eq(Coinbase::Transaction::Status::BROADCAST)
        end

        it 'sets the approve transaction signed payload' do
          expect(broadcasted_trade.transaction.signed_payload).to eq(signed_payload)
        end
      end

      context 'and the approve transaction is not signed' do
        before { trade.transaction.sign(from_key) }

        it 'raises an error' do
          expect { broadcasted_trade }.to raise_error(Coinbase::TransactionNotSignedError)
        end
      end

      context 'and the transaction is not signed' do
        before { trade.approve_transaction.sign(from_key) }

        it 'raises an error' do
          expect { broadcasted_trade }.to raise_error(Coinbase::TransactionNotSignedError)
        end
      end
    end
  end

  describe '#reload' do
    let(:updated_transaction_model) do
      Coinbase::Client::Transaction.new(
        status: 'complete',
        from_address_id: address_id,
        unsigned_payload: unsigned_payload
      )
    end

    let(:updated_to_amount) { BigDecimal(500_000_000) }
    let(:updated_usdc_amount) do
      Coinbase::Asset.from_model(usdc_asset).from_atomic_amount(updated_to_amount)
    end

    let(:updated_model) do
      Coinbase::Client::Trade.new(
        network_id: network_id,
        wallet_id: wallet_id,
        address_id: address_id,
        from_asset: from_asset_model,
        to_asset: to_asset_model,
        from_amount: from_amount.to_s,
        to_amount: updated_to_amount.to_s,
        trade_id: trade_id,
        transaction: updated_transaction_model
      )
    end

    before do
      allow(trades_api)
        .to receive(:get_trade)
        .with(trade.wallet_id, trade.address_id, trade.id)
        .and_return(updated_model)
    end

    it 'updates the trade transaction' do
      expect(trade.transaction.status).to eq(Coinbase::Transaction::Status::PENDING)
      expect(trade.reload.transaction.status).to eq(Coinbase::Transaction::Status::COMPLETE)
    end

    it 'updates properties on the trade' do
      expect(trade.to_amount).to eq(usdc_amount)
      expect(trade.reload.to_amount).to eq(updated_usdc_amount)
    end
  end

  describe '#wait!' do
    let(:updated_model) do
      Coinbase::Client::Trade.new(
        network_id: network_id,
        wallet_id: wallet_id,
        address_id: address_id,
        from_asset: from_asset_model,
        to_asset: to_asset_model,
        from_amount: from_amount.to_s,
        to_amount: to_amount.to_s,
        trade_id: trade_id,
        transaction: updated_transaction_model
      )
    end

    before do
      # TODO: This isn't working for some reason.
      allow(trade).to receive(:sleep)

      allow(trades_api)
        .to receive(:get_trade)
        .with(trade.wallet_id, trade.address_id, trade.id)
        .and_return(model, model, updated_model)
    end

    context 'when the trade is completed' do
      let(:updated_transaction_model) do
        Coinbase::Client::Transaction.new(
          status: 'complete',
          from_address_id: address_id,
          unsigned_payload: unsigned_payload
        )
      end

      it 'returns the completed Trade' do
        expect(trade.wait!).to eq(trade)
        expect(trade.status).to eq(Coinbase::Transaction::Status::COMPLETE)
      end
    end

    context 'when the trade is failed' do
      let(:updated_transaction_model) do
        Coinbase::Client::Transaction.new(
          status: 'failed',
          from_address_id: address_id,
          unsigned_payload: unsigned_payload
        )
      end

      it 'returns the failed Trade' do
        expect(trade.wait!).to eq(trade)
        expect(trade.status).to eq(Coinbase::Transaction::Status::FAILED)
      end
    end

    context 'when the trade times out' do
      let(:updated_transaction_model) do
        Coinbase::Client::Transaction.new(
          status: 'pending',
          from_address_id: address_id,
          unsigned_payload: unsigned_payload
        )
      end

      it 'raises a Timeout::Error' do
        expect { trade.wait!(0.2, 0.00001) }.to raise_error(Timeout::Error, 'Trade timed out')
      end
    end
  end

  describe '#inspect' do
    it 'includes trade details' do
      expect(trade.inspect).to include(
        trade_id,
        Coinbase.to_sym(network_id).to_s,
        address_id,
        from_asset_model.asset_id,
        eth_amount.to_s,
        to_asset_model.asset_id,
        usdc_amount.to_s,
        trade.status.to_s
      )
    end

    it 'returns the same value as to_s' do
      expect(trade.inspect).to eq(trade.to_s)
    end

    context 'when the trade has been broadcast on chain' do
      let(:transaction_model) do
        Coinbase::Client::Transaction.new(
          status: 'broadcast',
          from_address_id: address_id,
          unsigned_payload: unsigned_payload,
          signed_payload: signed_payload,
          transaction_hash: transaction_hash
        )
      end

      it 'includes the updated status' do
        expect(trade.inspect).to include('broadcast')
      end
    end
  end
end
