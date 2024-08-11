# frozen_string_literal: true

describe Coinbase::ExternalAddress do
  subject(:address) { described_class.new(network_id, address_id) }

  let(:network_id) { :ethereum_mainnet }
  let(:normalized_network_id) { 'ethereum-mainnet' }
  let(:address_id) { '0x1234' }

  describe '#initialize' do
    it 'initializes a new Address' do
      expect(address).to be_a(described_class)
    end
  end

  describe '#network_id' do
    it 'returns the network ID' do
      expect(address.network_id).to eq(network_id)
    end
  end

  describe '#id' do
    it 'returns the address ID' do
      expect(address.id).to eq(address_id)
    end
  end

  it_behaves_like 'an address that supports balance queries'
  it_behaves_like 'an address that supports requesting faucet funds'
  it_behaves_like 'an address that supports staking'
end
