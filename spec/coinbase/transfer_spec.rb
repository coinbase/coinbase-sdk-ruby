# frozen_string_literal: true

describe Coinbase::Transfer do
  let(:from_key) { Eth::Key.new }
  let(:to_key) { Eth::Key.new }
  let(:network_id) { :base_sepolia }
  let(:wallet_id) { SecureRandom.uuid }
  let(:from_address_id) { from_key.address.to_s }
  let(:amount) { 500_000_000_000_000_000 }
  let(:to_address_id) { to_key.address.to_s }
  let(:client) { double('Jimson::Client') }

  subject(:transfer) do
    described_class.new(network_id, wallet_id, from_address_id, amount, :eth, to_address_id, client: client)
  end

  describe '#initialize' do
    it 'initializes a new Transfer' do
      expect(transfer).to be_a(Coinbase::Transfer)
    end

    it 'does not initialize a new transfer for an invalid asset' do
      expect {
        Coinbase::Transfer.new(network_id, wallet_id, from_address_id, amount, :uni, to_address_id, client: client)
      }.to raise_error(ArgumentError, 'Unsupported asset: uni')
    end
  end
end
