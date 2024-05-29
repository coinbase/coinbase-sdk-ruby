# frozen_string_literal: true

describe Coinbase::Trade do
  let(:from_key) { Eth::Key.new }
  let(:network_id) { :base_sepolia }
  let(:wallet_id) { SecureRandom.uuid }
  let(:address_id) { from_key.address.to_s }
  let(:from_amount) { BigDecimal(100) }
  let(:to_amount) { BigDecimal(100_000) }
  let(:eth_amount) { from_amount / BigDecimal(Coinbase::WEI_PER_ETHER.to_s) }
  let(:usdc_amount) { to_amount / Coinbase::ATOMIC_UNITS_PER_USDC }
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
  let(:eth_asset) do
    Coinbase::Client::Asset.new(network_id: 'base-sepolia', asset_id: 'eth', decimals: 18)
  end
  let(:usdc_asset) do
    Coinbase::Client::Asset.new(network_id: 'base-sepolia', asset_id: 'usdc', decimals: 6)
  end
  let(:transaction_model) do
    Coinbase::Client::Transaction.new(
      status: 'pending',
      unsigned_payload: unsigned_payload
    )
  end
  let(:from_asset) { eth_asset }
  let(:to_asset) { usdc_asset }
  let(:model) do
    Coinbase::Client::Trade.new(
      network_id: network_id,
      wallet_id: wallet_id,
      address_id: address_id,
      from_asset: from_asset,
      to_asset: to_asset,
      from_amount: from_amount.to_s,
      to_amount: to_amount.to_s,
      trade_id: trade_id,
      transaction: transaction_model
    )
  end
  let(:trades_api) { double('Coinbase::Client::TradesApi') }
  let(:client) { double('Jimson::Client') }

  before(:each) do
    allow(Coinbase::Client::TradesApi).to receive(:new).and_return(trades_api)
  end

  subject(:trade) do
    described_class.new(model)
  end

  describe '#initialize' do
    it 'initializes a new Trade' do
      expect(trade).to be_a(Coinbase::Trade)
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
      let(:from_asset) do
        Coinbase::Client::Asset.new(network_id: 'base-sepolia', asset_id: 'other', decimals: decimals)
      end

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
      let(:to_asset) do
        Coinbase::Client::Asset.new(network_id: 'base-sepolia', asset_id: 'other', decimals: decimals)
      end

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

  describe '#reload' do
    let(:updated_transaction_model) do
      Coinbase::Client::Transaction.new(status: 'complete', unsigned_payload: unsigned_payload)
    end

    let(:updated_to_amount) { BigDecimal(500_000_000) }

    let(:updated_model) do
      Coinbase::Client::Trade.new(
        network_id: network_id,
        wallet_id: wallet_id,
        address_id: address_id,
        from_asset: from_asset,
        to_asset: to_asset,
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
      expect(trade.reload.to_amount).to eq(updated_to_amount / Coinbase::ATOMIC_UNITS_PER_USDC)
    end
  end

  describe '#wait!' do
    let(:updated_model) do
      Coinbase::Client::Trade.new(
        network_id: network_id,
        wallet_id: wallet_id,
        address_id: address_id,
        from_asset: from_asset,
        to_asset: to_asset,
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
        from_asset.asset_id,
        eth_amount.to_s,
        to_asset.asset_id,
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
