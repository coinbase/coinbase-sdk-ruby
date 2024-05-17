# frozen_string_literal: true

describe Coinbase::Wallet do
  let(:client) { double('Jimson::Client') }
  let(:wallet_id) { SecureRandom.uuid }
  let(:network_id) { 'base-sepolia' }
  let(:model) { Coinbase::Client::Wallet.new({ 'id': wallet_id, 'network_id': network_id }) }
  let(:address_model1) do
    Coinbase::Client::Address.new(
      {
        'address_id': '0x919538116b4F25f1CE01429fd9Ed7964556bf565',
        'wallet_id': wallet_id,
        'public_key': '0292df2f2c31a5c4b0d4946e922cc3bd25ad7196ffeb049905b0952b9ac48ef25f',
        'network_id': network_id
      }
    )
  end
  let(:address_model2) do
    Coinbase::Client::Address.new(
      {
        'address_id': '0xf23692a9DE556Ee1711b172Bf744C5f33B13DC89',
        'wallet_id': wallet_id,
        'public_key': '034ecbfc86f7447c8bfd1a5f71b13600d767ccb58d290c7b146632090f3a05c66c',
        'network_id': network_id
      }
    )
  end
  let(:model_with_default_address) do
    Coinbase::Client::Wallet.new(
      {
        'id': wallet_id,
        'network_id': network_id,
        'default_address': address_model1
      }
    )
  end
  let(:seed) { '000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f' }
  let(:wallets_api) { double('Coinbase::Client::WalletsApi') }
  let(:addresses_api) { double('Coinbase::Client::AddressesApi') }
  let(:transfers_api) { double('Coinbase::Client::TransfersApi') }

  subject(:wallet) { described_class.new(model) }

  before do
    allow(Coinbase::Client::AddressesApi).to receive(:new).and_return(addresses_api)
    allow(Coinbase::Client::WalletsApi).to receive(:new).and_return(wallets_api)
  end

  describe '.import' do
    let(:client) { double('Jimson::Client') }
    let(:wallet_id) { SecureRandom.uuid }
    let(:wallet_model) { Coinbase::Client::Wallet.new({ 'id': wallet_id, 'network_id': network_id }) }
    let(:address_list_model) do
      Coinbase::Client::AddressList.new(
        {
          'data' => [address_model1, address_model2],
          'total_count' => 2
        }
      )
    end
    let(:exported_data) do
      Coinbase::Wallet::Data.new(
        wallet_id: wallet_id,
        seed: seed
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

    context 'when there are no addresses' do
      let(:address_list_model) { Coinbase::Client::AddressList.new({ 'data' => [], 'total_count' => 0 }) }

      it 'loads the wallet addresses' do
        expect(imported_wallet.addresses.length).to eq(0)
      end
    end
  end

  describe '.create' do
    let(:wallet_id) { SecureRandom.uuid }
    let(:create_wallet_request) do
      { wallet: { network_id: network_id } }
    end
    let(:request) { { create_wallet_request: create_wallet_request } }
    let(:wallet_model) { Coinbase::Client::Wallet.new({ 'id': wallet_id, 'network_id': network_id }) }
    let(:default_address_model) do
      Coinbase::Client::Address.new(
        {
          'address_id': '0xdeadbeef',
          'wallet_id': wallet_id,
          'public_key': '0x1234567890',
          'network_id': network_id
        }
      )
    end

    subject(:created_wallet) { described_class.create }

    before do
      allow(wallets_api).to receive(:create_wallet).with(request).and_return(wallet_model)

      allow(addresses_api)
        .to receive(:create_address)
        .with(
          wallet_id,
          satisfy do |opts|
            public_key_present = opts[:create_address_request][:public_key].is_a?(String)
            attestation_present = opts[:create_address_request][:attestation].is_a?(String)
            public_key_present && attestation_present
          end
        ).and_return(address_model1)

      allow(wallets_api)
        .to receive(:get_wallet)
        .with(wallet_id)
        .and_return(model_with_default_address)
    end

    it 'creates a new wallet' do
      expect(created_wallet).to be_a(Coinbase::Wallet)
    end

    it 'creates a default address' do
      expect(created_wallet.default_address).to be_a(Coinbase::Address)
      expect(created_wallet.addresses.length).to eq(1)
    end

    context 'when setting the network ID explicitly' do
      let(:network_id) { 'base-mainnet' }

      subject(:created_wallet) do
        described_class.create(network_id: network_id)
      end

      it 'creates a new wallet' do
        expect(created_wallet).to be_a(Coinbase::Wallet)
      end

      it 'sets the specified network ID' do
        expect(created_wallet.network_id).to eq(:base_mainnet)
      end
    end
  end

  describe '#initialize' do
    context 'when no seed or address models are provided' do
      subject(:wallet) { described_class.new(model) }

      it 'initializes a new Wallet' do
        expect(wallet).to be_a(Coinbase::Wallet)
      end

      it 'sets the model' do
        expect(wallet.model).to eq(model)
      end

      it 'sets the master seed' do
        expect(wallet.instance_variable_get(:@master)).to be_a(MoneyTree::Master)
      end

      it 'sets the private key index' do
        expect(wallet.instance_variable_get(:@private_key_index)).to eq(0)
      end
    end

    context 'when a seed is provided' do
      let(:seed_wallet) { described_class.new(model, seed: seed) }

      it 'initializes a new Wallet with the provided seed' do
        expect(seed_wallet).to be_a(Coinbase::Wallet)
      end

      context 'when the seed is invalid' do
        let(:seed) { 'invalid' }

        it 'raises an error for an invalid seed' do
          expect { seed_wallet }.to raise_error(ArgumentError, 'Seed must be 32 bytes')
        end
      end
    end

    context 'when only the address models are provided' do
      it 'raises an error' do
        expect do
          described_class.new(model, address_models: [address_model1, address_model2])
        end.to raise_error(ArgumentError, 'Seed must be present if address_models are provided')
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
      it 'raises an error' do
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
      seedless_wallet.seed = seed
      expect(seedless_wallet.can_sign?).to be true
      expect(seedless_wallet.default_address.can_sign?).to be true
    end

    it 'raises an error for an invalid seed' do
      expect do
        seedless_wallet.seed = 'invalid seed'
      end.to raise_error(ArgumentError, 'Seed must be 32 bytes')
    end

    it 'raises an error if the wallet is already hydrated' do
      expect do
        wallet.seed = seed
      end.to raise_error('Seed is already set')
    end

    it 'raises an error if it is the wrong seed' do
      expect do
        seedless_wallet.seed = '86fc9fba421dcc6ad42747f14132c3cd975bd9fb1454df84ce5ea554f2542fbf'
      end.to raise_error(/Seed does not match wallet/)
    end
  end

  describe '#create_address' do
    let(:expected_public_key) { created_address_model.public_key }

    let(:wallet) do
      described_class.new(model, seed: seed)
    end

    subject(:created_address) { wallet.create_address }

    before do
      allow(addresses_api)
        .to receive(:create_address)
        .with(
          wallet_id,
          satisfy do |req|
            public_key = req[:create_address_request][:public_key]
            attestation = req[:create_address_request][:attestation]

            public_key == expected_public_key && attestation.is_a?(String)
          end
        ).and_return(created_address_model)
    end

    context 'when no addresses exist' do
      let(:created_address_model) { address_model1 }

      before do
        allow(wallets_api)
          .to receive(:get_wallet)
          .with(wallet_id)
          .and_return(model_with_default_address)
      end

      it 'creates a new address' do
        expect(created_address).to be_a(Coinbase::Address)
      end

      it 'reloads the wallet with the new default address' do
        expect(created_address).to eq(wallet.default_address)
      end
    end

    context 'when an address already exists', focus: true do
      let(:created_address_model) { address_model2 }

      let(:wallet) do
        described_class.new(model_with_default_address, seed: seed, address_models: [address_model1])
      end

      before { created_address }

      it 'creates a new address' do
        expect(created_address).to be_a(Coinbase::Address)
      end

      it 'updates the address count' do
        expect(wallet.addresses.length).to eq(2)
      end

      it 'is not sets as the default address' do
        expect(created_address).not_to eq(wallet.default_address)
      end
    end
  end

  describe '#default_address' do
    it 'returns the first address' do
      expect(wallet.default_address).to eq(wallet.addresses.first)
    end
  end

  describe '#address' do
    let(:address_models) { [address_model1, address_model2] }
    let(:wallet) do
      described_class.new(model, seed: '', address_models: address_models)
    end
    subject(:address) { wallet.address(address_model2.address_id) }

    it 'returns the correct address' do
      expect(address).to be_a(Coinbase::Address)
      expect(address.id).to eq(address_model2.address_id)
    end
  end

  describe '#addresses' do
    let(:address_models) { [address_model1, address_model2] }
    subject(:wallet) do
      described_class.new(model, seed: '', address_models: address_models)
    end

    it 'returns an address for each address model' do
      expect(wallet.addresses.length).to eq(2)
      expect(wallet.addresses.each_with_index.all? do |address, i|
        address.id == address_models[i].address_id
      end).to be true
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
    let(:other_wallet) do
      described_class.new(
        Coinbase::Client::Wallet.new(
          {
            'id': wallet_id,
            'network_id': 'base-sepolia',
            'default_address': address_model2
          }
        ),
        seed: '',
        address_models: [address_model2]
      )
    end

    subject(:wallet) do
      described_class.new(model_with_default_address, seed: '', address_models: [address_model1])
    end

    context 'when the destination is a Wallet' do
      let(:destination) { other_wallet }
      let(:to_address_id) { destination.default_address.id }

      before do
        allow(wallet.default_address)
          .to receive(:transfer)
          .with(amount, asset_id, to_address_id)
          .and_return(transfer)
      end

      it 'creates a transfer to the default address ID' do
        expect(wallet.transfer(amount, asset_id, destination)).to eq(transfer)
      end
    end

    context 'when the desination is an Address' do
      let(:destination) { other_wallet.default_address }
      let(:to_address_id) { destination.id }

      before do
        allow(wallet.default_address)
          .to receive(:transfer)
          .with(amount, asset_id, to_address_id)
          .and_return(transfer)
      end

      it 'creates a transfer to the address ID' do
        expect(wallet.transfer(amount, asset_id, destination)).to eq(transfer)
      end
    end

    context 'when the destination is a String' do
      let(:destination) { '0x1234567890' }

      before do
        allow(wallet.default_address)
          .to receive(:transfer)
          .with(amount, asset_id, destination)
          .and_return(transfer)
      end

      it 'creates a transfer to the address ID' do
        expect(wallet.transfer(amount, asset_id, destination)).to eq(transfer)
      end
    end
  end

  describe '#export' do
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
      Coinbase::Client::FaucetTransaction.new({ 'transaction_hash': '0x123456789' })
    end
    let(:wallet) do
      described_class.new(model_with_default_address, seed: '', address_models: [address_model1])
    end
    subject(:faucet_transaction) { wallet.faucet }

    before do
      allow(addresses_api)
        .to receive(:request_faucet_funds)
        .with(wallet_id, address_model1.address_id)
        .and_return(faucet_transaction_model)
    end

    it 'returns the faucet transaction' do
      expect(faucet_transaction).to be_a(Coinbase::FaucetTransaction)
    end

    it 'contains the transaction hash' do
      expect(faucet_transaction.transaction_hash).to eq(faucet_transaction_model.transaction_hash)
    end
  end

  describe '#can_sign?' do
    it 'returns true if the wallet is hydrated' do
      expect(wallet.can_sign?).to be true
    end

    context 'when the wallet is not hydrated' do
      subject(:wallet) { described_class.new(model, seed: '', address_models: [address_model1]) }

      it 'returns false' do
        expect(wallet.can_sign?).to be false
      end
    end
  end

  describe '#inspect' do
    it 'includes wallet details' do
      expect(wallet.inspect).to include(wallet_id, Coinbase.to_sym(network_id).to_s)
    end

    it 'returns the same value as to_s' do
      expect(wallet.inspect).to eq(wallet.to_s)
    end

    context 'when the model has a default address' do
      subject(:wallet) do
        described_class.new(model_with_default_address, seed: '', address_models: [address_model1])
      end

      it 'includes the default address' do
        expect(wallet.inspect).to include(address_model1.address_id)
      end
    end
  end
end
