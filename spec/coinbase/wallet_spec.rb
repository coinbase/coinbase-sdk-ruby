# frozen_string_literal: true

describe Coinbase::Wallet do
  subject(:wallet) { described_class.new }

  let(:api_key_file) { 'spec/fixtures/coinbase_cloud_api_key.json' }

  before do
    Coinbase.init_json(api_key_file)
  end

  describe '#initialize' do
    it 'initializes a new Wallet' do
      expect(wallet).to be_a(Coinbase::Wallet)
    end
  end

  describe '#create_address' do
    it 'creates a new address' do
      address = wallet.create_address
      expect(address).to be_a(Coinbase::Address)
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
    it 'returns the correct address' do
      default_address = wallet.default_address
      expect(wallet.get_address(default_address.address_id)).to eq(default_address)
    end
  end

  describe '#list_addresses' do
    it 'contains one address' do
      expect(wallet.list_addresses.length).to eq(1)
    end
  end

  describe '#list_balances' do
    it 'returns a hash with an ETH balance' do
      expect(wallet.list_balances).to eq({ eth: BigDecimal(0) })
    end
  end
end
