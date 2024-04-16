# frozen_string_literal: true

describe Coinbase::Wallet do
  subject(:wallet) { described_class.new }

  before do
    Coinbase.init
  end

  describe '#initialize' do
    it 'initializes a new Wallet' do
      expect(wallet).to be_a(Coinbase::Wallet)
    end

    context 'when a seed is provided' do
      let(:seed) { '000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f' }
      let(:seed_wallet) { described_class.new(seed: seed) }

      it 'initializes a new Wallet with the provided seed' do
        expect(seed_wallet).to be_a(Coinbase::Wallet)
      end

      it 'raises an error for an invalid seed' do
        expect do
          described_class.new(seed: 'invalid')
        end.to raise_error(ArgumentError, 'Seed must be 32 bytes')
      end
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

  describe '#get_balance' do
    it 'returns the ETH balance' do
      expect(wallet.get_balance(:eth)).to eq(BigDecimal(0))
    end
  end
end
