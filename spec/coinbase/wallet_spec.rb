# frozen_string_literal: true

describe Coinbase::Wallet do
  subject(:wallet) { described_class.new }

  describe '#initialize' do
    it 'initializes a new Wallet' do
      expect(wallet).to be_a(Coinbase::Wallet)
    end
  end

  describe '#list_addresses' do
    it 'contains one address' do
      expect(wallet.list_addresses.length).to eq(1)
    end
  end
end
