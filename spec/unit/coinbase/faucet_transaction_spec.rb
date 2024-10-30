# frozen_string_literal: true

describe Coinbase::FaucetTransaction do
  subject(:faucet_transaction) { described_class.new(model) }

  let(:network_id) { :base_sepolia }
  let(:transaction_hash) { '0x6c087c1676e8269dd81e0777244584d0cbfd39b6997b3477242a008fa9349e11' }
  let(:transaction_link) { "https://sepolia.basescan.org/tx/#{transaction_hash}" }
  let(:address_id) { Eth::Key.new.address.to_s }
  let(:transaction_model) do
    build(
      :transaction_model,
      :broadcasted,
      network_id,
      to_address_id: address_id,
      transaction_hash: transaction_hash,
      transaction_link: transaction_link
    )
  end
  let(:model) do
    Coinbase::Client::FaucetTransaction.new(transaction: transaction_model)
  end

  let(:external_addresses_api) { instance_double(Coinbase::Client::ExternalAddressesApi) }

  before do
    allow(Coinbase::Client::ExternalAddressesApi).to receive(:new).and_return(external_addresses_api)
  end

  describe '#initialize' do
    it 'initializes a new FaucetTransaction' do
      expect(faucet_transaction).to be_a(described_class)
    end
  end

  describe '#transaction' do
    it 'returns the transaction' do
      expect(faucet_transaction.transaction).to be_a(Coinbase::Transaction)
    end
  end

  describe '#transaction_hash' do
    it 'returns the transaction hash' do
      expect(faucet_transaction.transaction_hash).to eq(transaction_hash)
    end
  end

  describe '#status' do
    it 'returns the transaction status' do
      expect(faucet_transaction.status).to eq(Coinbase::Transaction::Status::BROADCAST)
    end
  end

  describe '#transaction_link' do
    it 'returns the transaction link' do
      expect(faucet_transaction.transaction_link).to eq(transaction_link)
    end
  end

  describe '#network' do
    it 'returns the network' do
      expect(faucet_transaction.network).to be_a(Coinbase::Network)
    end
  end

  describe '#reload' do
    let(:updated_transaction_model) do
      build(
        :transaction_model,
        :completed,
        to_address_id: address_id,
        transaction_hash: transaction_hash,
        transaction_link: transaction_link
      )
    end
    let(:updated_model) do
      Coinbase::Client::FaucetTransaction.new(transaction: updated_transaction_model)
    end

    before do
      allow(external_addresses_api)
        .to receive(:get_faucet_transaction)
        .with('base-sepolia', address_id, transaction_hash)
        .and_return(updated_model)
    end

    it 'updates the faucet transaction' do
      expect(faucet_transaction.reload.transaction.status).to eq(Coinbase::Transaction::Status::COMPLETE)
    end
  end

  describe '#wait!' do
    before do
      allow(faucet_transaction).to receive(:sleep) # rubocop:disable RSpec/SubjectStub

      allow(external_addresses_api)
        .to receive(:get_faucet_transaction)
        .with('base-sepolia', address_id, transaction_hash)
        .and_return(model, model, updated_model)
    end

    context 'when the faucet transaction is completed' do
      let(:updated_model) { build(:faucet_tx_model, network_id, :completed) }

      it 'returns the completed FaucetTransaction' do
        expect(faucet_transaction.wait!.status).to eq(Coinbase::Transaction::Status::COMPLETE)
      end
    end

    context 'when the faucet transaction is failed' do
      let(:updated_model) { build(:faucet_tx_model, network_id, :failed) }

      it 'returns the failed FaucetTransaction' do
        expect(faucet_transaction.wait!.status).to eq(Coinbase::Transaction::Status::FAILED)
      end
    end

    context 'when the faucet transaction times out' do
      let(:updated_model) { build(:faucet_tx_model, network_id, :broadcasted) }

      it 'raises a Timeout::Error' do
        expect { faucet_transaction.wait!(0.2, 0.00001) }.to raise_error(Timeout::Error, 'Faucet transaction timed out')
      end
    end
  end

  describe '#to_s' do
    it 'returns a string representation of the FaucetTransaction' do
      expect(faucet_transaction.to_s).to include(
        'Coinbase::FaucetTransaction',
        transaction_hash,
        transaction_link,
        'broadcast'
      )
    end
  end

  describe '#inspect' do
    it 'returns the same string representation as #to_s' do
      expect(faucet_transaction.inspect).to eq(faucet_transaction.to_s)
    end
  end
end
