# frozen_string_literal: true

describe Coinbase::Wallet do
  subject(:wallet) { described_class.new }

  describe '#initialize' do
    it 'initializes a new Wallet' do
      expect(wallet).to be_a(Coinbase::Wallet)
    end
  end

  describe '#create_address' do
    it 'creates a new address' do
      address = wallet.create_address
      expect(address).to be_a(String)
      expect(wallet.list_addresses.length).to eq(2)
      expect(address).not_to eq(wallet.default_address)
    end
  end

  describe '#default_address' do
    it 'returns the first address' do
      expect(wallet.default_address).to eq(wallet.list_addresses.first)
    end
  end

  describe '#get_address' do
    it 'returns the first address' do
      default_address = wallet.default_address
      expect(wallet.get_address(default_address)).to eq(default_address)
    end
  end

  describe '#list_addresses' do
    it 'contains one address' do
      expect(wallet.list_addresses.length).to eq(1)
    end
  end
end
