# frozen_string_literal: true

describe Coinbase::FaucetTransaction do
  subject(:faucet_transaction) { described_class.new(model) }

  let(:transaction_hash) { '0x6c087c1676e8269dd81e0777244584d0cbfd39b6997b3477242a008fa9349e11' }
  let(:transaction_link) { "https://sepolia.basescan.org/tx/#{transaction_hash}" }
  let(:model) do
    Coinbase::Client::FaucetTransaction.new(
      transaction_hash: transaction_hash,
      transaction_link: transaction_link
    )
  end

  describe '#initialize' do
    it 'initializes a new FaucetTransaction' do
      expect(faucet_transaction).to be_a(described_class)
    end
  end

  describe '#transaction_hash' do
    it 'returns the transaction hash' do
      expect(faucet_transaction.transaction_hash).to eq(transaction_hash)
    end
  end

  describe '#transaction_link' do
    it 'returns the transaction link' do
      expect(faucet_transaction.transaction_link).to eq(transaction_link)
    end
  end

  describe '#to_s' do
    it 'returns a string representation of the FaucetTransaction' do
      expect(faucet_transaction.to_s).to eq(
        "Coinbase::FaucetTransaction{transaction_hash: '#{transaction_hash}', transaction_link: '#{transaction_link}'}"
      )
    end
  end

  describe '#inspect' do
    it 'returns the same string representation as #to_s' do
      expect(faucet_transaction.inspect).to eq(faucet_transaction.to_s)
    end
  end
end
