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
  let(:addresses_api) { double('Coinbase::Client::AddressesApi') }
  let(:transfers_api) { double('Coinbase::Client::TransfersApi') }
  let(:client) { double('Jimson::Client') }

  before(:each) do
    allow(Coinbase.configuration).to receive(:base_sepolia_client).and_return(client)
    allow(Coinbase::Client::AddressesApi).to receive(:new).and_return(addresses_api)
    allow(Coinbase::Client::TransfersApi).to receive(:new).and_return(transfers_api)
  end

  subject(:address) do
    described_class.new(model, key)
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
    let(:response) do
      Coinbase::Client::AddressBalanceList.new(
        'data' => [
          Coinbase::Client::Balance.new(
            {
              'amount' => '1000000000000000000',
              'asset' => Coinbase::Client::Asset.new({
                                                       'network_id': 'base-sepolia',
                                                       'asset_id': 'eth',
                                                       'decimals': 18
                                                     })
            }
          ),
          Coinbase::Client::Balance.new(
            {
              'amount' => '5000',
              'asset' => Coinbase::Client::Asset.new({
                                                       'network_id': 'base-sepolia',
                                                       'asset_id': 'usdc',
                                                       'decimals': 6
                                                     })
            }
          )
        ]
      )
    end

    it 'returns a hash with balances' do
      expect(addresses_api)
        .to receive(:list_address_balances)
        .with(wallet_id, address_id)
        .and_return(response)
      expect(address.list_balances).to eq(eth: BigDecimal('1'), usdc: BigDecimal('5000'))
    end
  end

  describe '#get_balance' do
    let(:response) do
      Coinbase::Client::Balance.new(
        {
          'amount' => '1000000000000000000',
          'asset' => Coinbase::Client::Asset.new({
                                                   'network_id': 'base-sepolia',
                                                   'asset_id': 'eth',
                                                   'decimals': 18
                                                 })
        }
      )
    end

    it 'returns the correct ETH balance' do
      expect(addresses_api)
        .to receive(:get_address_balance)
        .with(wallet_id, address_id, 'eth')
        .and_return(response)
      expect(address.get_balance(:eth)).to eq BigDecimal('1')
    end

    it 'returns the correct Gwei balance' do
      expect(addresses_api)
        .to receive(:get_address_balance)
        .with(wallet_id, address_id, 'eth')
        .and_return(response)
      expect(address.get_balance(:gwei)).to eq BigDecimal('1_000_000_000')
    end

    it 'returns the correct Wei balance' do
      expect(addresses_api)
        .to receive(:get_address_balance)
        .with(wallet_id, address_id, 'eth')
        .and_return(response)
      expect(address.get_balance(:wei)).to eq BigDecimal('1_000_000_000_000_000_000')
    end

    it 'returns 0 for an unsupported asset' do
      expect(addresses_api)
        .to receive(:get_address_balance)
        .with(wallet_id, address_id, 'uni')
        .and_return(nil)
      expect(address.get_balance(:uni)).to eq BigDecimal('0')
    end
  end

  describe '#transfer' do
    let(:eth_balance_response) do
      Coinbase::Client::Balance.new(
        {
          'amount' => '1000000000000000000',
          'asset' => Coinbase::Client::Asset.new({
                                                   'network_id': 'base-sepolia',
                                                   'asset_id': 'eth',
                                                   'decimals': 18
                                                 })
                                                }
      )
    end
    let(:usdc_balance_response) do
      Coinbase::Client::Balance.new(
        {
          'amount' => '5000',
          'asset' => Coinbase::Client::Asset.new({
                                                    'network_id': 'base-sepolia',
                                                    'asset_id': 'usdc',
                                                    'decimals': 6
                                                  })
        }
      )
    end
    let(:to_key) { Eth::Key.new }
    let(:to_address_id) { to_key.address.to_s }
    let(:transaction_hash) { '0xdeadbeef' }
    let(:raw_signed_transaction) { '0123456789abcdef' }
    let(:transaction) { double('Transaction', sign: transaction_hash, hex: raw_signed_transaction) }
    let(:transfer) do
      double('Transfer', transaction: transaction)
    end

    before do
      allow(Coinbase::Transfer).to receive(:new).and_return(transfer)
      allow(client).to receive(:eth_sendRawTransaction).with("0x#{raw_signed_transaction}").and_return(transaction_hash)
    end

    # TODO: Add test case for when the destination is a Wallet.

    context 'when the destination is a valid Address' do
      let(:asset_id) { :wei }
      let(:amount) { 500_000_000_000_000_000 }
      let(:destination) { described_class.new(model, to_key) }
      let(:create_transfer_request) do
        { amount: amount.to_s, network_id: network_id, asset_id: 'eth', destination: destination.address_id }
      end

      it 'creates a Transfer' do
        expect(addresses_api)
          .to receive(:get_address_balance)
          .with(wallet_id, address_id, 'eth')
          .and_return(eth_balance_response)
        expect(transfers_api)
          .to receive(:create_transfer)
          .with(wallet_id, address_id, create_transfer_request)
        expect(address.transfer(amount, asset_id, destination)).to eq(transfer)
      end
    end

    context 'when the destination is a valid Address and asset is USDC' do
      let(:asset_id) { :usdc }
      let(:amount) { 500 }
      let(:destination) { described_class.new(model, to_key) }
      let(:create_transfer_request) do
        { amount: amount.to_s, network_id: network_id, asset_id: 'usdc', destination: destination.address_id }
      end

      it 'creates a Transfer' do
        expect(addresses_api)
          .to receive(:get_address_balance)
          .with(wallet_id, address_id, 'usdc')
          .and_return(usdc_balance_response)
        expect(transfers_api)
          .to receive(:create_transfer)
          .with(wallet_id, address_id, create_transfer_request)
        expect(address.transfer(amount, asset_id, destination)).to eq(transfer)
      end
    end

    context 'when the destination is a valid Address ID' do
      let(:asset_id) { :wei }
      let(:amount) { 500_000_000_000_000_000 }
      let(:destination) { to_address_id }
      let(:create_transfer_request) do
        { amount: amount.to_s, network_id: network_id, asset_id: 'eth', destination: to_address_id }
      end
      it 'creates a Transfer' do
        expect(addresses_api)
          .to receive(:get_address_balance)
          .with(wallet_id, address_id, 'eth')
          .and_return(eth_balance_response)
        expect(transfers_api)
          .to receive(:create_transfer)
          .with(wallet_id, address_id,  create_transfer_request)
        expect(address.transfer(amount, asset_id, destination)).to eq(transfer)
      end
    end

    context 'when the destination is a valid Address ID and asset is Gwei' do
      let(:asset_id) { :gwei }
      let(:amount) { 500_000_000 }
      let(:wei_amount) { 500_000_000_000_000_000 }
      let(:destination) { to_address_id }
      let(:create_transfer_request) do
        { amount: wei_amount.to_s, network_id: network_id, asset_id: 'eth', destination: to_address_id }
      end
      it 'creates a Transfer' do
        expect(addresses_api)
          .to receive(:get_address_balance)
          .with(wallet_id, address_id, 'eth')
          .and_return(eth_balance_response)
        expect(transfers_api)
          .to receive(:create_transfer)
          .with(wallet_id, address_id,  create_transfer_request)
        expect(address.transfer(amount, asset_id, destination)).to eq(transfer)
      end
    end

    context 'when the asset is unsupported' do
      let(:amount) { 500_000_000_000_000_000 }
      it 'raises an ArgumentError' do
        expect { address.transfer(amount, :uni, to_address_id) }.to raise_error(ArgumentError, 'Unsupported asset: uni')
      end
    end

    # TODO: Add test case for when the destination is a Wallet.

    context 'when the destination Address is on a different network' do
      let(:asset_id) { :wei }
      let(:amount) { 500_000_000_000_000_000 }
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
          address.transfer(amount, asset_id, Coinbase::Address.new(new_model, to_key))
        end.to raise_error(ArgumentError, 'Transfer must be on the same Network')
      end
    end

    context 'when the balance is insufficient' do
      let(:asset_id) { :wei }
      let(:excessive_amount) { 9_000_000_000_000_000_000_000 }
      before do
        expect(addresses_api)
          .to receive(:get_address_balance)
          .with(wallet_id, address_id, 'eth')
          .and_return(eth_balance_response)
      end

      it 'raises an ArgumentError' do
        expect do
          address.transfer(excessive_amount, asset_id, to_address_id)
        end.to raise_error(ArgumentError)
      end
    end
  end

  describe '#to_s' do
    it 'returns the address as a string' do
      expect(address.to_s).to eq(address_id)
    end
  end
end
