# frozen_string_literal: true

describe Coinbase::Address do
  subject(:address) { described_class.new(network_id, address_id) }

  let(:network) { build(:network, :ethereum_mainnet) }
  let(:network_id) { :ethereum_mainnet }
  let(:normalized_network_id) { 'ethereum-mainnet' }
  let(:address_id) { '0x1234' }

  before do
    allow(Coinbase::Network).to receive(:from_id).with(network_id).and_return(network)
  end

  describe '#id' do
    subject { address.id }

    it { is_expected.to eq(address_id) }
  end

  describe '#network' do
    subject { address.network }

    it { is_expected.to eq(network) }
  end

  describe '#to_s' do
    subject { address.to_s }

    it { is_expected.to include(network_id.to_s, address_id) }
  end

  describe '#inspect' do
    it 'matches to_s' do
      expect(address.inspect).to eq(address.to_s)
    end
  end

  describe '#can_sign?' do
    subject { address.can_sign? }

    it { is_expected.to be(false) }
  end

  it_behaves_like 'an address that supports balance queries'
  it_behaves_like 'an address that supports requesting faucet funds'
  it_behaves_like 'an address that supports transaction queries'
end
