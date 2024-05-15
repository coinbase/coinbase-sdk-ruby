# frozen_string_literal: true

describe Coinbase::Wallet do
  let(:client) { double('Jimson::Client') }
  let(:wallet_id) { SecureRandom.uuid }
  let(:network_id) { 'base-sepolia' }
  let(:model) { Coinbase::Client::Wallet.new({ 'id': wallet_id, 'network_id': network_id }) }
  let(:address_model1) do
    Coinbase::Client::Address.new({
                                    'address_id': '0xfbd9D61057eC1debCeEE12C62812Fb3E1d025201',
                                    'wallet_id': wallet_id,
                                    'public_key': '0x1234567890',
                                    'network_id': network_id
                                  })
  end
  let(:model_with_default_address) do
    Coinbase::Client::Wallet.new(
      {
        'id': wallet_id,
        'network_id': 'base-sepolia',
        'default_address': address_model1
      }
    )
  end
  let(:wallets_api) { double('Coinbase::Client::WalletsApi') }
  let(:addresses_api) { double('Coinbase::Client::AddressesApi') }
  let(:transfers_api) { double('Coinbase::Client::TransfersApi') }

  subject(:wallet) { described_class.new(model) }

  before do
    allow(Coinbase::Client::AddressesApi).to receive(:new).and_return(addresses_api)
    allow(Coinbase::Client::WalletsApi).to receive(:new).and_return(wallets_api)
    allow(addresses_api).to receive(:create_address).and_return(address_model1)
    allow(addresses_api).to receive(:get_address).and_return(address_model1)
    allow(wallets_api).to receive(:get_wallet).with(wallet_id).and_return(model_with_default_address)
  end

  describe '#import' do
    let(:client) { double('Jimson::Client') }
    let(:wallet_id) { SecureRandom.uuid }
    let(:wallet_model) { Coinbase::Client::Wallet.new({ 'id': wallet_id, 'network_id': 'base-sepolia' }) }
    let(:create_wallet_request) { { wallet: { network_id: network_id } } }
    let(:opts) { { create_wallet_request: create_wallet_request } }
    let(:address_list_model) do
      Coinbase::Client::AddressList.new({ 'data' => [address_model1], 'total_count' => 1 })
    end
    let(:exported_data) do
      Coinbase::Wallet::Data.new(
        wallet_id: wallet_id,
        seed: '86fc9fba421dcc6ad42747f14132c3cd975bd9fb1454df84ce5ea554f2542fbe'
      )
    end
    subject(:imported_wallet) { Coinbase::Wallet.import(exported_data) }

    before do
      expect(wallets_api).to receive(:get_wallet).with(wallet_id).and_return(model_with_default_address)
      expect(addresses_api)
        .to receive(:list_addresses)
        .with(wallet_id, { limit: 20 })
        .and_return(address_list_model)
    end

    it 'imports an exported wallet' do
      expect(imported_wallet.id).to eq(wallet_id)
    end

    it 'loads the wallet addresses' do
      expect(imported_wallet.addresses.length).to eq(address_list_model.total_count)
    end

    it 'contains the same seed when re-exported' do
      expect(imported_wallet.export.seed).to eq(exported_data.seed)
    end
  end

  describe '#initialize' do
    context 'when no seed or address models are provided' do
      it 'initializes a new Wallet' do
        expect(addresses_api)
          .to receive(:create_address)
          .with(wallet_id, satisfy do |opts|
            public_key_present = opts[:create_address_request][:public_key].is_a?(String)
            attestation_present = opts[:create_address_request][:attestation].is_a?(String)
            public_key_present && attestation_present
          end)
        expect(wallet).to be_a(Coinbase::Wallet)
      end
    end

    context 'when a seed is provided' do
      let(:seed) { '000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f' }
      let(:seed_wallet) { described_class.new(model, seed: seed) }

      it 'initializes a new Wallet with the provided seed' do
        expect(addresses_api)
          .to receive(:create_address)
          .with(wallet_id, satisfy do |opts|
            public_key_present = opts[:create_address_request][:public_key].is_a?(String)
            attestation_present = opts[:create_address_request][:attestation].is_a?(String)
            public_key_present && attestation_present
          end)
          .and_return(address_model1)
        expect(seed_wallet).to be_a(Coinbase::Wallet)
      end

      it 'raises an error for an invalid seed' do
        expect do
          described_class.new(model, seed: 'invalid')
        end.to raise_error(ArgumentError, 'Seed must be 32 bytes')
      end
    end

    context 'when only the address models are provided' do
      let(:address_model2) do
        Coinbase::Client::Address.new({
                                        'address_id': '0x945F8F802Ec6d7fc69E417B93609A51E100a25FE',
                                        'wallet_id': wallet_id,
                                        'public_key': '0xabcd',
                                        'network_id': network_id
                                      })
      end
      let(:address_wallet) do
      end

      it 'initializes a new Wallet with the provided address models' do
        expect do
          described_class.new(model, address_models: [address_model1, address_model2])
        end.to raise_error(ArgumentError)
      end
    end

    context 'when the seed is empty but the address models are provided' do
      it 'creates an unhydrated wallet' do
        wallet = described_class.new(model, seed: '', address_models: [address_model1])
        expect(wallet).to be_a(Coinbase::Wallet)
        expect(wallet.addresses.length).to eq(1)
      end
    end

    context 'when the seed is empty and no address models are provided' do
      it 'throws an error' do
        expect do
          described_class.new(model, seed: '')
        end.to raise_error(ArgumentError, 'Seed must be empty if address_models are not provided')
      end
    end
  end

  describe '#wallet_id' do
    it 'returns the Wallet ID' do
      expect(wallet.id).to eq(wallet_id)
    end
  end

  describe '#network_id' do
    it 'returns the Network ID' do
      expect(wallet.network_id).to eq(:base_sepolia)
    end
  end

  describe '#seed=' do
    let(:seedless_wallet) do
      described_class.new(model_with_default_address, seed: '', address_models: [address_model1])
    end

    it 'sets the seed' do
      seedless_wallet.seed = '86fc9fba421dcc6ad42747f14132c3cd975bd9fb1454df84ce5ea554f2542fbe'
      expect(seedless_wallet.can_sign?).to be true
      expect(seedless_wallet.default_address.can_sign?).to be true
    end
  end

  describe '#create_address' do
    it 'creates a new address' do
      expect(wallet.addresses.length).to eq(1)

      expect(addresses_api)
        .to receive(:create_address)
        .with(wallet_id, satisfy do |opts|
          public_key_present = opts[:create_address_request][:public_key].is_a?(String)
          attestation_present = opts[:create_address_request][:attestation].is_a?(String)
          public_key_present && attestation_present
        end)
        .and_return(address_model1)
        .exactly(1).times

      address = wallet.create_address
      expect(address).to be_a(Coinbase::Address)
      expect(wallet.addresses.length).to eq(2)
      expect(address).not_to eq(wallet.default_address)
    end
  end

  describe '#default_address' do
    it 'returns the first address' do
      expect(wallet.default_address).to eq(wallet.addresses.first)
    end
  end

  describe '#address' do
    before do
      allow(addresses_api).to receive(:create_address).and_return(address_model1)
    end

    it 'returns the correct address' do
      default_address = wallet.default_address
      expect(wallet.address(default_address.id)).to eq(default_address)
    end
  end

  describe '#addresses' do
    it 'contains one address' do
      expect(wallet.addresses.length).to eq(1)
    end
  end

  describe '#balances' do
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
              'amount' => '5000000',
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
    before do
      expect(wallets_api).to receive(:list_wallet_balances).and_return(response)
    end

    it 'returns a hash with an ETH and USDC balance' do
      expect(wallet.balances).to eq({ eth: BigDecimal(1), usdc: BigDecimal(5) })
    end
  end

  describe '#balance' do
    let(:response) do
      Coinbase::Client::Balance.new(
        {
          'amount' => '5000000000000000000',
          'asset' => Coinbase::Client::Asset.new({
                                                   'network_id': 'base-sepolia',
                                                   'asset_id': 'eth',
                                                   'decimals': 18
                                                 })
        }
      )
    end

    before do
      expect(wallets_api).to receive(:get_wallet_balance).with(wallet_id, 'eth').and_return(response)
    end

    it 'returns the correct ETH balance' do
      expect(wallet.balance(:eth)).to eq(BigDecimal(5))
    end

    it 'returns the correct Gwei balance' do
      expect(wallet.balance(:gwei)).to eq(BigDecimal(5 * Coinbase::GWEI_PER_ETHER))
    end

    it 'returns the correct Wei balance' do
      expect(wallet.balance(:wei)).to eq(BigDecimal(5 * Coinbase::WEI_PER_ETHER))
    end
  end

  describe '#transfer' do
    let(:transfer) { double('Coinbase::Transfer') }
    let(:amount) { 5 }
    let(:asset_id) { :eth }

    context 'when the destination is a Wallet' do
      let(:destination) { described_class.new(model) }
      let(:to_address_id) { destination.default_address.id }

      before do
        expect(wallet.default_address).to receive(:transfer).with(amount, asset_id, to_address_id).and_return(transfer)
      end

      it 'creates a transfer to the default address ID' do
        expect(wallet.transfer(amount, asset_id, destination)).to eq(transfer)
      end
    end

    context 'when the desination is an Address' do
      let(:destination) { wallet.create_address }
      let(:to_address_id) { destination.id }

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

  describe '#export' do
    let(:seed) { '000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f' }
    let(:address_model1) do
      Coinbase::Client::Address.new({
                                      'address_id': '0xf23692a9DE556Ee1711b172Bf744C5f33B13DC89',
                                      'wallet_id': wallet_id,
                                      'public_key': '0xabcd',
                                      'network_id': network_id
                                    })
    end
    let(:address_model2) do
      Coinbase::Client::Address.new({
                                      'address_id': '0x919538116b4F25f1CE01429fd9Ed7964556bf565',
                                      'wallet_id': wallet_id,
                                      'public_key': '0xefgh',
                                      'network_id': network_id
                                    })
    end
    let(:seed_wallet) do
      described_class.new(model, seed: seed, address_models: [address_model1, address_model2])
    end

    it 'exports the wallet data' do
      wallet_data = seed_wallet.export
      expect(wallet_data).to be_a(Coinbase::Wallet::Data)
      expect(wallet_data.wallet_id).to eq(seed_wallet.id)
      expect(wallet_data.seed).to eq(seed)
    end

    it 'allows for re-creation of a Wallet' do
      wallet_data = seed_wallet.export
      new_wallet = described_class
                   .new(model, seed: wallet_data.seed, address_models: [address_model1, address_model2])
      expect(new_wallet.addresses.length).to eq(2)
      new_wallet.addresses.each_with_index do |address, i|
        expect(address.id).to eq(seed_wallet.addresses[i].id)
      end
    end
  end

  describe '#faucet' do
    let(:faucet_transaction_model) do
      Coinbase::Client::FaucetTransaction.new({
                                                'transaction_hash': '0x123456789'
                                              })
    end

    before do
      expect(addresses_api)
        .to receive(:request_faucet_funds)
        .with(wallet_id, address_model1.address_id)
        .and_return(faucet_transaction_model)
    end

    it 'returns the faucet transaction' do
      faucet_transaction = wallet.faucet
      expect(faucet_transaction).to be_a(Coinbase::FaucetTransaction)
      expect(faucet_transaction.transaction_hash).to eq(faucet_transaction_model.transaction_hash)
    end
  end

  describe '#can_sign?' do
    it 'returns true if the wallet is hydrated' do
      expect(wallet.can_sign?).to be true
    end

    it 'returns false if the wallet is not hydrated' do
      wallet = described_class.new(model, seed: '', address_models: [address_model1])
      expect(wallet.can_sign?).to be false
    end
  end

  describe '#inspect' do
    it 'includes wallet details' do
      expect(wallet.inspect).to include(wallet_id, Coinbase.to_sym(network_id).to_s, address_model1.address_id)
    end

    it 'returns the same value as to_s' do
      expect(wallet.inspect).to eq(wallet.to_s)
    end
  end
end
