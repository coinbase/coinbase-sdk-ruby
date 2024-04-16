# frozen_string_literal: true

describe Coinbase::Wallet do
  let(:client) { double('Jimson::Client') }
  subject(:wallet) { described_class.new(client: client) }

  describe '#initialize' do
    it 'initializes a new Wallet' do
      expect(wallet).to be_a(Coinbase::Wallet)
    end

    context 'when a seed is provided' do
      let(:seed) { '000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f' }
      let(:seed_wallet) { described_class.new(seed: seed, client: client) }

      it 'initializes a new Wallet with the provided seed' do
        expect(seed_wallet).to be_a(Coinbase::Wallet)
      end

      it 'raises an error for an invalid seed' do
        expect do
          described_class.new(seed: 'invalid', client: client)
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
    before do
      expect(wallet.default_address).to receive(:list_balances).and_return({ eth: BigDecimal(1) })
    end

    it 'returns a hash with an ETH balance' do
      expect(wallet.list_balances).to eq({ eth: BigDecimal(1) })
    end
  end

  describe '#get_balance' do
    before do
      expect(wallet.default_address).to receive(:list_balances).and_return({ eth: BigDecimal(5) })
    end

    it 'returns the correct ETH balance' do
      expect(wallet.get_balance(:eth)).to eq(BigDecimal(5))
    end

    it 'returns the correct Gwei balance' do
      expect(wallet.get_balance(:gwei)).to eq(BigDecimal(5 * Coinbase::GWEI_PER_ETHER))
    end

    it 'returns the correct Wei balance' do
      expect(wallet.get_balance(:wei)).to eq(BigDecimal(5 * Coinbase::WEI_PER_ETHER))
    end
  end

  describe '#transfer' do
    let(:transfer) { double('Coinbase::Transfer') }
    let(:amount) { 5 }
    let(:asset_id) { :eth }

    context 'when the destination is a Wallet' do
      let(:destination) { described_class.new(client: client) }
      let(:to_address_id) { destination.default_address.address_id }

      before do
        expect(wallet.default_address).to receive(:transfer).with(amount, asset_id, to_address_id).and_return(transfer)
      end

      it 'creates a transfer to the default address ID' do
        expect(wallet.transfer(amount, asset_id, destination)).to eq(transfer)
      end
    end

    context 'when the desination is an Address' do
      let(:destination) { wallet.create_address }
      let(:to_address_id) { destination.address_id }

      before do
        expect(wallet.default_address).to receive(:transfer).with(amount, asset_id, to_address_id).and_return(transfer)
      end

      it 'creates a transfer to the address ID' do
        expect(wallet.transfer(amount, asset_id, destination)).to eq(transfer)
      end
    end

    context 'when the destination is a String' do
      let(:destination) { '0x1234567890' }

      before do
        expect(wallet.default_address).to receive(:transfer).with(amount, asset_id, destination).and_return(transfer)
      end

      it 'creates a transfer to the address ID' do
        expect(wallet.transfer(amount, asset_id, destination)).to eq(transfer)
      end
    end
  end
end
