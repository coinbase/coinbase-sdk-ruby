# frozen_string_literal: true

describe Coinbase::Address do
  let(:key) { Eth::Key.new }
  let(:network_id) { :base_sepolia }
  let(:address_id) { key.address.to_s }
  let(:wallet_id) { SecureRandom.uuid }
  let(:model) do
    Coinbase::Client::Address.new({
                                    'network_id' => 'base-sepolia',
                                    'address_id' => address_id,
                                    'wallet_id' => wallet_id,
                                    'public_key' => key.public_key.compressed.unpack1('H*')
                                  })
  end
  let(:client) { double('Jimson::Client') }

  subject(:address) do
    described_class.new(model, key, client: client)
  end

  describe '#initialize' do
    it 'initializes a new Address' do
      expect(address).to be_a(Coinbase::Address)
    end
  end

  describe '#network_id' do
    it 'returns the network ID' do
      expect(address.network_id).to eq(network_id)
    end
  end

  describe '#address_id' do
    it 'returns the address ID' do
      expect(address.address_id).to eq(address_id)
    end
  end

  describe '#wallet_id' do
    it 'returns the wallet ID' do
      expect(address.wallet_id).to eq(wallet_id)
    end
  end

  describe '#list_balances' do
    before do
      allow(client).to receive(:eth_getBalance).with(address_id, 'latest').and_return('0xde0b6b3a7640000')
    end

    it 'returns a hash with an ETH balance' do
      expect(address.list_balances).to eq(eth: BigDecimal('1'))
    end
  end

  describe '#get_balance' do
    before do
      allow(client).to receive(:eth_getBalance).with(address_id, 'latest').and_return('0xde0b6b3a7640000')
    end

    it 'returns the correct ETH balance' do
      expect(address.get_balance(:eth)).to eq BigDecimal('1')
    end

    it 'returns the correct Gwei balance' do
      expect(address.get_balance(:gwei)).to eq BigDecimal('1_000_000_000')
    end

    it 'returns the correct Wei balance' do
      expect(address.get_balance(:wei)).to eq BigDecimal('1_000_000_000_000_000_000')
    end

    it 'returns 0 for an unsupported asset' do
      expect(address.get_balance(:uni)).to eq BigDecimal('0')
    end
  end

  describe '#transfer' do
    let(:amount) { 500_000_000_000_000_000 }
    let(:asset_id) { :wei }
    let(:to_key) { Eth::Key.new }
    let(:to_address_id) { to_key.address.to_s }
    let(:transaction_hash) { '0xdeadbeef' }
    let(:raw_signed_transaction) { '0123456789abcdef' }
    let(:transaction) { double('Transaction', sign: transaction_hash, hex: raw_signed_transaction) }
    let(:transfer) do
      double('Transfer', transaction: transaction)
    end

    before do
      allow(client).to receive(:eth_getBalance).with(address_id, 'latest').and_return('0xde0b6b3a7640000')
      allow(Coinbase::Transfer).to receive(:new).and_return(transfer)
      allow(client).to receive(:eth_sendRawTransaction).with("0x#{raw_signed_transaction}").and_return(transaction_hash)
    end

    # TODO: Add test case for when the destination is a Wallet.

    context 'when the destination is a valid Address' do
      let(:destination) { described_class.new(model, to_key, client: client) }

      it 'creates a Transfer' do
        expect(address.transfer(amount, asset_id, destination)).to eq(transfer)
      end
    end

    context 'when the destination is a valid Address ID' do
      let(:destination) { to_address_id }

      it 'creates a Transfer' do
        expect(address.transfer(amount, asset_id, destination)).to eq(transfer)
      end
    end

    context 'when the asset is unsupported' do
      it 'raises an ArgumentError' do
        expect { address.transfer(amount, :uni, to_address_id) }.to raise_error(ArgumentError, 'Unsupported asset: uni')
      end
    end

    # TODO: Add test case for when the destination is a Wallet.

    context 'when the destination Address is on a different network' do
      let(:new_model) do
        Coinbase::Client::Address.new({
                                        'network_id' => 'base-mainnet',
                                        'address_id' => address_id,
                                        'wallet_id' => wallet_id,
                                        'public_key' => key.public_key.compressed.unpack1('H*')
                                      })
      end

      it 'raises an ArgumentError' do
        expect do
          address.transfer(amount, asset_id, Coinbase::Address.new(new_model, to_key, client: client))
        end.to raise_error(ArgumentError, 'Transfer must be on the same Network')
      end
    end

    context 'when the balance is insufficient' do
      before do
        allow(client).to receive(:eth_getBalance).with(address_id, 'latest').and_return('0x0')
      end

      it 'raises an ArgumentError' do
        expect do
          address.transfer(amount, asset_id, to_address_id)
        end.to raise_error(ArgumentError, "Insufficient funds: #{amount} requested, but only 0.0 available")
      end
    end
  end

  describe '#to_s' do
    it 'returns the address as a string' do
      expect(address.to_s).to eq(address_id)
    end
  end
end
