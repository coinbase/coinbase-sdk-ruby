# frozen_string_literal: true

describe Coinbase::Client::BalanceHistoryApi do
  subject(:address) { described_class.new(network_id) }

  let(:network) { build(:network, :ethereum_mainnet) }
  let(:network_id) { :ethereum_mainnet }
  let(:normalized_network_id) { 'ethereum-mainnet' }
  let(:address_id) { '0x1234' }

  before do
    allow(Coinbase::Network).to receive(:from_id).with(network_id).and_return(network)
  end

  describe '#initialize' do
    it 'initializes a new Address' do
      expect(address).to be_a(described_class)
    end
  end

  it_behaves_like 'an address that supports balance queries'
end
