# frozen_string_literal: true

describe Coinbase::Wallet do
  let(:wallet_id) { SecureRandom.uuid }
  let(:network) { :base_sepolia }
  let(:network_id) { Coinbase.normalize_network(network) }
  let(:seed) { '000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f' }
  let(:model) { build(:wallet_model, network, :without_default_address, id: wallet_id) }
  let(:model_with_default_address) { build(:wallet_model, network, id: wallet_id, seed: seed) }
  let(:model_with_seed_pending) do
    build(:wallet_model, network, :server_signer_pending, id: wallet_id, seed: seed)
  end
  let(:model_with_seed_active) do
    build(:wallet_model, network, :server_signer_active, id: wallet_id, seed: seed)
  end
  let(:address_model1) do
    build(:address_model, network, :with_seed, seed: seed, wallet_id: wallet_id, index: 0)
  end
  let(:address_model2) do
    build(:address_model, network, :with_seed, seed: seed, wallet_id: wallet_id, index: 1)
  end
  let(:wallets_api) { double('Coinbase::Client::WalletsApi') }
  let(:addresses_api) { double('Coinbase::Client::AddressesApi') }
  let(:transfers_api) { double('Coinbase::Client::TransfersApi') }
  let(:use_server_signer) { false }
  let(:configuration) do
    instance_double(Coinbase::Configuration, use_server_signer: use_server_signer, api_client: nil)
  end

  subject(:wallet) { described_class.new(model) }

  before do
    allow(Coinbase::Client::AddressesApi).to receive(:new).and_return(addresses_api)
    allow(Coinbase::Client::WalletsApi).to receive(:new).and_return(wallets_api)

    allow(Coinbase).to receive(:configuration).and_return(configuration)
  end

  describe '.list' do
    let(:api) { wallets_api }
    let(:fetch_params) { ->(page) { [{ limit: 100, page: page }] } }
    let(:resource_list_klass) { Coinbase::Client::WalletList }
    let(:item_klass) { Coinbase::Wallet }
    let(:item_initialize_args) { { seed: '' } }
    let(:create_model) { ->(id) { build(:wallet_model, network, :without_default_address, id: id) } }
    subject(:enumerator) { described_class.list }

    it_behaves_like 'it is a paginated enumerator', :wallets
  end

  describe '.fetch' do
    subject(:fetched_wallet) { described_class.fetch(wallet_id) }

    before do
      allow(wallets_api).to receive(:get_wallet).with(wallet_id).and_return(model_with_default_address)
    end

    it 'returns a Wallet' do
      expect(fetched_wallet).to be_a(Coinbase::Wallet)
    end

    it 'calls the get wallet endpoint' do
      expect(wallets_api).to receive(:get_wallet).with(wallet_id)

      fetched_wallet
    end

    it 'sets the model instance variable' do
      expect(fetched_wallet.instance_variable_get(:@model)).to eq(model_with_default_address)
    end

    it 'returns a wallet that cannot sign' do
      expect(fetched_wallet.can_sign?).to be(false)
    end
  end

  describe '.import' do
    let(:wallet_id) { SecureRandom.uuid }
    let(:wallet_model) { build(:wallet_model, network, id: wallet_id) }
    let(:exported_data) { Coinbase::Wallet::Data.new(wallet_id: wallet_id, seed: seed) }

    subject(:imported_wallet) { Coinbase::Wallet.import(exported_data) }

    before do
      allow(wallets_api).to receive(:get_wallet).with(wallet_id).and_return(model_with_default_address)
    end

    context 'when not using server signer' do
      let(:use_server_signer) { false }

      it 'imports an exported wallet' do
        expect(imported_wallet.id).to eq(wallet_id)
      end

      it 'contains the same seed when re-exported' do
        expect(imported_wallet.export.seed).to eq(exported_data.seed)
      end
    end

    context 'when using a server signer' do
      let(:use_server_signer) { true }

      it 'imports a wallet with id' do
        expect(imported_wallet.id).to eq(wallet_id)
      end

      it 'cannot export the wallet' do
        expect do
          imported_wallet.export
        end.to raise_error 'Cannot export data for Server-Signer backed Wallet'
      end
    end

    context 'when the data is invalid' do
      subject(:imported_wallet) { Coinbase::Wallet.import({ invalid: 'data' }) }

      it 'raises an error for invalid data' do
        expect { imported_wallet }.to raise_error(ArgumentError)
      end
    end
  end

  describe '.create' do
    let(:wallet_id) { SecureRandom.uuid }
    let(:create_wallet_request) do
      { wallet: { network_id: network_id, use_server_signer: use_server_signer } }
    end
    let(:request) { { create_wallet_request: create_wallet_request } }
    let(:wallet_model) { build(:wallet_model, network, id: wallet_id) }

    subject(:created_wallet) { described_class.create }

    before do
      allow(wallets_api).to receive(:create_wallet).with(request).and_return(wallet_model)

      # During address creation we check if there are any addresses in the wallet, before
      # creating an address.
      allow(addresses_api)
        .to receive(:list_addresses)
        .with(wallet_id, { limit: 20 })
        .and_return(Coinbase::Client::AddressList.new(data: [], total_count: 0))
    end

    context 'when not using a server signer' do
      let(:use_server_signer) { false }
      before do
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
    end

    context 'when setting the network ID explicitly' do
      let(:network) { :base_mainnet }
      let(:use_server_signer) { false }

      before do
        allow(addresses_api)
          .to receive(:create_address)
          .with(
            wallet_id,
            satisfy do |req|
              public_key = req[:create_address_request][:public_key]
              attestation = req[:create_address_request][:attestation]

              public_key.is_a?(String) && attestation.is_a?(String)
            end
          ).and_return(address_model1)

        allow(wallets_api)
          .to receive(:get_wallet)
          .with(wallet_id)
          .and_return(model_with_default_address)
      end

      subject(:created_wallet) do
        described_class.create(network_id: network)
      end

      it 'creates a new wallet' do
        expect(created_wallet).to be_a(Coinbase::Wallet)
      end

      it 'sets the specified network ID' do
        expect(created_wallet.network_id).to eq(:base_mainnet)
      end

      context 'when using a network symbol' do
        let(:network_id) { :base_mainnet }
        let(:create_wallet_request) do
          { wallet: { network_id: 'base-mainnet', use_server_signer: use_server_signer } }
        end

        it 'creates a new wallet' do
          expect(created_wallet).to be_a(Coinbase::Wallet)
        end

        it 'sets the specified network ID' do
          expect(created_wallet.network_id).to eq(:base_mainnet)
        end
      end
    end

    context 'when using a server signer' do
      let(:use_server_signer) { true }
      before do
        allow(addresses_api)
          .to receive(:create_address)
          .with(wallet_id, { create_address_request: {} })
          .and_return(address_model1)

        allow(wallets_api)
          .to receive(:get_wallet)
          .with(wallet_id)
          .and_return(model_with_seed_active)
      end

      subject(:created_wallet) do
        described_class.create(interval_seconds: 0.2, timeout_seconds: 0.00001)
      end

      it 'creates a new wallet' do
        expect(created_wallet).to be_a(Coinbase::Wallet)
      end

      it 'creates a default address' do
        expect(created_wallet.default_address).to be_a(Coinbase::Address)
        expect(created_wallet.addresses.length).to eq(1)
      end

      it 'sets the default network ID' do
        expect(created_wallet.network_id).to eq(:base_sepolia)
      end
    end

    context 'when using a server signer is not active' do
      let(:use_server_signer) { true }
      before do
        allow(wallets_api)
          .to receive(:get_wallet)
          .with(wallet_id)
          .and_return(model_with_seed_pending)
      end

      subject(:created_wallet) do
        described_class.create(interval_seconds: 0.2, timeout_seconds: 0.00001)
      end

      it 'raises a Timeout::Error' do
        expect do
          created_wallet
        end.to raise_error(Timeout::Error, 'Wallet creation timed out. Check status of your Server-Signer')
      end
    end
  end

  describe '#initialize' do
    subject(:wallet) { described_class.new(model) }

    it 'initializes a new Wallet' do
      expect(wallet).to be_a(Coinbase::Wallet)
    end

    it 'sets the model instance variable' do
      expect(wallet.instance_variable_get(:@model)).to eq(model)
    end

    context 'when the model is not a wallet' do
      it 'raises an error' do
        expect do
          described_class.new(nil)
        end.to raise_error(ArgumentError, 'model must be a Wallet')
      end
    end

    context 'when no seed is provided' do
      before do
        allow(MoneyTree::Master).to receive(:new).and_call_original
      end

      it 'initializes a new Wallet' do
        expect(wallet).to be_a(Coinbase::Wallet)
      end

      it 'initializes a new master seed' do
        expect(MoneyTree::Master).to receive(:new).with(no_args)

        wallet
      end

      it 'sets the master seed' do
        expect(wallet.instance_variable_get(:@master)).to be_a(MoneyTree::Master)
      end

      it 'can sign' do
        expect(wallet.can_sign?).to be(true)
      end
    end

    context 'when a seed is provided' do
      subject(:wallet) { described_class.new(model, seed: seed) }

      before do
        allow(MoneyTree::Master).to receive(:new).and_call_original
      end

      it 'initializes a new Wallet' do
        expect(wallet).to be_a(Coinbase::Wallet)
      end

      it 'initializes a master seed with the specified value' do
        expect(MoneyTree::Master).to receive(:new).with(seed_hex: seed)

        wallet
      end

      it 'sets the master seed' do
        expect(wallet.instance_variable_get(:@master).seed_hex).to eq(seed)
      end

      it 'can sign' do
        expect(wallet.can_sign?).to be(true)
      end

      context 'when the seed is invalid' do
        let(:seed) { 'invalid' }

        it 'raises an error for an invalid seed' do
          expect { wallet }.to raise_error(ArgumentError, 'Seed must be 32 bytes')
        end
      end

      context 'when the seed is empty' do
        let(:seed) { '' }

        it 'initializes a new Wallet' do
          expect(wallet).to be_a(Coinbase::Wallet)
        end

        it 'does not generate a new master seed' do
          expect(MoneyTree::Master).not_to receive(:new)

          wallet
        end

        it 'does not set the master seed' do
          expect(wallet.instance_variable_get(:@master)).to be_nil
        end

        it 'cannot sign' do
          expect(wallet.can_sign?).to be(false)
        end
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
      described_class.new(model_with_default_address, seed: '')
    end

    context 'when the addresses are not already loaded' do
      before do
        allow(addresses_api).to receive(:list_addresses)

        seedless_wallet.seed = seed
      end

      it 'marks the wallet as signable' do
        expect(seedless_wallet.can_sign?).to be(true)
      end

      it 'does not load the addresses' do
        expect(addresses_api).not_to have_received(:list_addresses)
      end

      it 'sets the seed' do
        expect(seedless_wallet.instance_variable_get(:@master)).to be_a(MoneyTree::Master)
      end

      context 'and the addresses are subsequently loaded' do
        before do
          allow(addresses_api)
            .to receive(:list_addresses)
            .with(wallet_id, { limit: 20 })
            .and_return(
              Coinbase::Client::AddressList.new(
                data: [address_model1, address_model2],
                total_count: 2
              )
            )
        end

        it 'marks the default address as signable' do
          expect(seedless_wallet.default_address.can_sign?).to be(true)
        end

        it 'marks all addresses as signable' do
          seedless_wallet.addresses.each do |address|
            expect(address.can_sign?).to be(true)
          end
        end
      end
    end

    context 'when the addresses are already loaded' do
      before do
        allow(addresses_api)
          .to receive(:list_addresses)
          .with(wallet_id, { limit: 20 })
          .and_return(
            Coinbase::Client::AddressList.new(
              data: [address_model1, address_model2],
              total_count: 1
            )
          )

        # Load the addresses
        seedless_wallet.addresses
      end

      context 'when the seed matches already derived addresses' do
        before { seedless_wallet.seed = seed }

        it 'sets the key on every address' do
          seedless_wallet.addresses.each do |address|
            expect(address.can_sign?).to be(true)
          end
        end
      end

      it 'raises an error if the seed does not match already derived addresses' do
        expect do
          seedless_wallet.seed = '86fc9fba421dcc6ad42747f14132c3cd975bd9fb1454df84ce5ea554f2542fbf'
        end.to raise_error(/Seed does not match wallet/)
      end
    end

    it 'raises an error for an invalid seed' do
      expect do
        seedless_wallet.seed = 'invalid seed'
      end.to raise_error(ArgumentError, 'Seed must be 32 bytes')
    end

    it 'raises an error for an empty seed' do
      expect do
        seedless_wallet.seed = ''
      end.to raise_error(ArgumentError, 'Seed must not be empty')
    end

    it 'raises an error for a nil seed' do
      expect do
        seedless_wallet.seed = nil
      end.to raise_error(ArgumentError, 'Seed must not be empty')
    end

    it 'raises an error if the wallet is already hydrated' do
      expect do
        wallet.seed = seed
      end.to raise_error('Seed is already set')
    end
  end

  describe '#create_address' do
    let(:expected_public_key) { created_address_model.public_key }
    let(:wallet) { described_class.new(model, seed: seed) }
    let(:existing_addresses) { [] }

    subject(:created_address) { wallet.create_address }

    before do
      allow(addresses_api)
        .to receive(:list_addresses)
        .with(wallet_id, { limit: 20 })
        .and_return(Coinbase::Client::AddressList.new(data: existing_addresses, total_count: existing_addresses.length))

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

    context 'when the wallet does not have a default address initially' do
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
        expect(wallet.default_address).to be_nil

        expect(created_address).to eq(wallet.default_address)
      end
    end

    context 'when an address already exists' do
      let(:existing_addresses) { [address_model1] }
      let(:created_address_model) { address_model2 }
      let(:wallet) { described_class.new(model_with_default_address, seed: seed) }

      before do
        created_address
      end

      it 'creates a new address' do
        expect(created_address).to be_a(Coinbase::Address)
      end

      it 'updates the address count' do
        expect(wallet.addresses.length).to eq(2)
      end

      it 'is not set as the default address' do
        expect(created_address).not_to eq(wallet.default_address)
      end
    end

    context 'when using a server signer' do
      let(:created_address_model) { address_model1 }

      subject(:created_address) { wallet.create_address }

      before do
        allow(addresses_api)
          .to receive(:create_address)
          .with(wallet_id).and_return(created_address_model)

        allow(wallets_api)
          .to receive(:get_wallet)
          .with(wallet_id)
          .and_return(model_with_default_address)
      end

      it 'creates a new address' do
        expect(created_address).to be_a(Coinbase::Address)
      end
    end
  end

  describe '#default_address' do
    let(:address_models) { [address_model1, address_model2] }
    let(:wallet) { described_class.new(model, seed: '') }

    before do
      allow(addresses_api)
        .to receive(:list_addresses)
        .with(wallet_id, { limit: 20 })
        .and_return(Coinbase::Client::AddressList.new(data: address_models, total_count: 2))
    end

    context 'when the wallet has a default address' do
      let(:expected_address) { Coinbase::WalletAddress.new(address_model1, nil) }
      subject(:wallet) { described_class.new(model_with_default_address, seed: '') }

      it 'returns the default address' do
        expect(wallet.default_address.id).to eq(address_model1.address_id)
      end

      it 'sets the wallet ID' do
        expect(wallet.default_address.wallet_id).to eq(wallet_id)
      end

      it 'returns a WalletAddress' do
        expect(wallet.default_address).to be_a(Coinbase::WalletAddress)
      end
    end

    context 'when the wallet does not have a default address' do
      it 'returns nil' do
        expect(wallet.default_address).to be_nil
      end
    end
  end

  describe '#address' do
    let(:address_models) { [address_model1, address_model2] }
    let(:wallet) { described_class.new(model, seed: '') }

    subject(:address) { wallet.address(address_model2.address_id) }

    before do
      allow(addresses_api)
        .to receive(:list_addresses)
        .with(wallet_id, { limit: 20 })
        .and_return(Coinbase::Client::AddressList.new(data: address_models, total_count: 2))
    end

    it 'returns the correct address' do
      expect(address).to be_a(Coinbase::Address)
      expect(address.id).to eq(address_model2.address_id)
    end
  end

  describe '#addresses' do
    let(:address_models) { [address_model1, address_model2] }
    let(:total_count) { address_models.length }
    subject(:wallet) { described_class.new(model, seed: '') }

    before do
      allow(addresses_api)
        .to receive(:list_addresses)
        .with(wallet_id, { limit: 20 })
        .and_return(Coinbase::Client::AddressList.new(data: address_models, total_count: 2))
    end

    context 'when there are no addresses' do
      let(:address_models) { [] }

      it 'returns an empty array' do
        expect(wallet.addresses).to be_empty
      end
    end

    context 'when the wallet is hydrated with a seed' do
      subject(:wallet) { described_class.new(model, seed: seed) }

      it 'returns all of the wallet addresses' do
        expect(wallet.addresses.length).to eq(total_count)
      end

      it 'returns the addresses from the server response' do
        wallet.addresses.each_with_index do |address, i|
          expect(address.id).to eq(address_models[i].address_id)
        end
      end

      it 'returns addresses that can sign' do
        expect(wallet.addresses.all?(&:can_sign?)).to be(true)
      end
    end

    context 'when the wallet is not hydrated with a seed' do
      it 'returns all of the wallet addresses' do
        expect(wallet.addresses.length).to eq(total_count)
      end

      it 'returns the addresses from the server response' do
        wallet.addresses.each_with_index do |address, i|
          expect(address.id).to eq(address_models[i].address_id)
        end
      end

      it 'returns addresses that cannot sign' do
        expect(wallet.addresses.all?(&:can_sign?)).to be(false)
      end
    end
  end

  describe '#balances' do
    let(:response) do
      Coinbase::Client::AddressBalanceList.new(
        data: [
          build(:balance_model, network, amount: '1000000000000000000'),
          build(:balance_model, network, :usdc, amount: '5000000')
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
    let(:eth_asset) { build(:asset_model) }
    let(:amount) { 5_000_000_000_000_000_000 }
    let(:response) { build(:balance_model, network, amount: amount) }

    before do
      expect(wallets_api).to receive(:get_wallet_balance).with(wallet_id, 'eth').and_return(response)
    end

    it 'returns the correct ETH balance' do
      expect(wallet.balance(:eth)).to eq(build(:asset, :eth).from_atomic_amount(amount))
    end

    it 'returns the correct Gwei balance' do
      expect(wallet.balance(:gwei)).to eq(build(:asset, :gwei).from_atomic_amount(amount))
    end

    it 'returns the correct Wei balance' do
      expect(wallet.balance(:wei)).to eq(build(:asset, :wei).from_atomic_amount(amount))
    end
  end

  context 'with a default address' do
    before do
      allow(addresses_api)
        .to receive(:list_addresses)
        .with(wallet_id, { limit: 20 })
        .and_return(Coinbase::Client::AddressList.new(data: [address_model1], total_count: 1))
    end

    subject(:wallet) { described_class.new(model_with_default_address, seed: '') }

    describe '#stake' do
      before do
        allow(wallet.default_address).to receive(:stake)
      end

      subject(:stake) { wallet.stake(5, :eth) }

      it 'calls stake' do
        subject
        expect(wallet.default_address).to have_received(:stake).with(5, :eth, mode: :default, options: {})
      end
    end

    describe '#unstake' do
      before do
        allow(wallet.default_address).to receive(:unstake)
      end

      subject(:unstake) { wallet.unstake(5, :eth) }

      it 'calls unstake' do
        subject
        expect(wallet.default_address).to have_received(:unstake).with(5, :eth, mode: :default, options: {})
      end
    end

    describe '#claim_stake' do
      before do
        allow(wallet.default_address).to receive(:claim_stake)
      end

      subject(:claim_stake) { wallet.claim_stake(5, :eth) }

      it 'calls claim_stake' do
        subject
        expect(wallet.default_address).to have_received(:claim_stake).with(5, :eth, mode: :default, options: {})
      end
    end

    describe '#staking_balances' do
      before do
        allow(wallet.default_address).to receive(:staking_balances)
      end

      subject(:staking_balances) { wallet.staking_balances(:eth) }

      it 'calls staking_balances' do
        subject
        expect(wallet.default_address).to have_received(:staking_balances).with(:eth, mode: :default, options: {})
      end
    end

    describe '#stakeable_balance' do
      before do
        allow(wallet.default_address).to receive(:stakeable_balance)
      end

      subject(:stakeable_balance) { wallet.stakeable_balance(:eth) }

      it 'calls stakeable_balance' do
        subject
        expect(wallet.default_address).to have_received(:stakeable_balance).with(:eth, mode: :default, options: {})
      end
    end

    describe '#unstakeable_balance' do
      before do
        allow(wallet.default_address).to receive(:unstakeable_balance)
      end

      subject(:unstakeable_balance) { wallet.unstakeable_balance(:eth) }

      it 'calls unstakeable_balance' do
        subject
        expect(wallet.default_address).to have_received(:unstakeable_balance).with(:eth, mode: :default, options: {})
      end
    end

    describe '#claimable_balance' do
      before do
        allow(wallet.default_address).to receive(:claimable_balance)
      end

      subject(:claimable_balance) { wallet.claimable_balance(:eth) }

      it 'calls claimable_balance' do
        subject
        expect(wallet.default_address).to have_received(:claimable_balance).with(:eth, mode: :default, options: {})
      end
    end
  end

  describe '#transfer' do
    let(:transfer) { double('Coinbase::Transfer') }
    let(:amount) { 5 }
    let(:asset_id) { :eth }
    let(:other_wallet_id) { SecureRandom.uuid }
    let(:other_wallet_model) do
      Coinbase::Client::Wallet.new(id: other_wallet_id, network_id: 'base-sepolia', default_address: address_model2)
    end
    let(:other_wallet) { described_class.new(other_wallet_model, seed: '') }

    before do
      allow(addresses_api)
        .to receive(:list_addresses)
        .with(other_wallet_id, { limit: 20 })
        .and_return(Coinbase::Client::AddressList.new(data: [address_model2], total_count: 1))

      allow(addresses_api)
        .to receive(:list_addresses)
        .with(wallet_id, { limit: 20 })
        .and_return(Coinbase::Client::AddressList.new(data: [address_model1], total_count: 1))
    end

    subject(:wallet) do
      described_class.new(model_with_default_address, seed: '')
    end

    context 'when the destination is a Wallet' do
      let(:destination) { other_wallet }

      before do
        allow(wallet.default_address)
          .to receive(:transfer)
          .with(amount, asset_id, destination)
          .and_return(transfer)
      end

      it 'creates a transfer from the default address to the wallet' do
        expect(wallet.transfer(amount, asset_id, destination)).to eq(transfer)
      end
    end

    context 'when the destination is an Address' do
      let(:destination) { other_wallet.default_address }

      before do
        allow(wallet.default_address)
          .to receive(:transfer)
          .with(amount, asset_id, destination)
          .and_return(transfer)
      end

      it 'creates a transfer from the default address to the address' do
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

      it 'creates a transfer from the default address to the address ID' do
        expect(wallet.transfer(amount, asset_id, destination)).to eq(transfer)
      end
    end
  end

  describe '#trade' do
    let(:trade) { double('Coinbase::Trade') }
    let(:amount) { 5 }
    let(:from_asset_id) { :eth }
    let(:to_asset_id) { :weth }

    subject(:wallet) do
      described_class.new(model_with_default_address, seed: '')
    end

    before do
      allow(addresses_api)
        .to receive(:list_addresses)
        .with(wallet_id, { limit: 20 })
        .and_return(Coinbase::Client::AddressList.new(data: [address_model1], total_count: 1))

      allow(wallet.default_address)
        .to receive(:trade)
        .with(amount, from_asset_id, to_asset_id)
        .and_return(trade)
    end

    it 'creates a trade from the default address' do
      expect(wallet.trade(amount, from_asset_id, to_asset_id)).to eq(trade)
    end
  end

  describe '#export' do
    context 'when not using a server signer' do
      let(:use_server_signer) { false }
      let(:seed_wallet) { described_class.new(model, seed: seed) }

      subject(:exported_data) { seed_wallet.export }

      it 'exports the wallet data' do
        expect(exported_data).to be_a(Coinbase::Wallet::Data)
      end

      it 'exports wallet data with the wallet ID' do
        expect(exported_data.wallet_id).to eq(seed_wallet.id)
      end

      it 'exports wallet data with the seed' do
        expect(exported_data.seed).to eq(seed)
      end
    end

    context 'when using a server signer' do
      let(:use_server_signer) { true }
      let(:wallet_without_seed) { described_class.new(model, seed: nil) }

      it 'does not export seed data' do
        expect do
          wallet_without_seed.export
        end.to raise_error 'Cannot export data for Server-Signer backed Wallet'
      end
    end
  end

  describe '#faucet' do
    let(:faucet_transaction_model) do
      Coinbase::Client::FaucetTransaction.new({ 'transaction_hash': '0x123456789' })
    end
    let(:wallet) { described_class.new(model_with_default_address, seed: '') }

    subject(:faucet_transaction) { wallet.faucet }

    before do
      allow(addresses_api)
        .to receive(:list_addresses)
        .with(wallet_id, { limit: 20 })
        .and_return(Coinbase::Client::AddressList.new(data: [address_model1], total_count: 1))

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
      subject(:wallet) { described_class.new(model, seed: '') }

      it 'returns false' do
        expect(wallet.can_sign?).to be false
      end
    end
  end

  describe '#save_seed!' do
    let(:initial_seed_data) { {} }
    let(:wallet) do
      described_class.new(model_with_default_address, seed: seed)
    end

    let(:file) do
      Tempfile.new.tap do |f|
        f.write(JSON.pretty_generate(initial_seed_data))
        f.rewind
      end
    end
    let(:file_path) { file.path }

    let(:configuration) do
      instance_double(
        Coinbase::Configuration,
        use_server_signer: use_server_signer,
        api_client: nil,
        api_key_private_key: OpenSSL::PKey::EC.generate('prime256v1').to_pem
      )
    end

    let(:saved_seed_data) { JSON.parse(File.read(file_path)) }

    after { file.unlink }

    context 'when encryption is false' do
      before do
        wallet.save_seed!(file_path, encrypt: false)
      end

      it 'saves the wallet data to the seed file' do
        expect(saved_seed_data[wallet.id])
          .to eq({ 'seed' => seed, 'encrypted' => false, 'iv' => '', 'auth_tag' => '' })
      end
    end

    context 'when encryption is true' do
      subject(:wallet_saved_data) { saved_seed_data[wallet.id] }

      before do
        wallet.save_seed!(file_path, encrypt: true)
      end

      it 'saves an encrypted seed' do
        expect(wallet_saved_data['seed']).not_to eq(seed)
      end

      it 'sets encrypted to true' do
        expect(wallet_saved_data['encrypted']).to eq(true)
      end

      it 'sets the IV' do
        expect(wallet_saved_data['iv']).not_to be_empty
      end

      it 'sets the auth tag' do
        expect(wallet_saved_data['auth_tag']).not_to be_empty
      end
    end

    context 'when the file does not exist' do
      let(:file_path) { '/tmp/missing.json' }

      before do
        wallet.save_seed!(file_path)
      end

      it 'saves the wallet data to the new file' do
        expect(saved_seed_data[wallet.id])
          .to eq({ 'seed' => seed, 'encrypted' => false, 'iv' => '', 'auth_tag' => '' })
      end
    end

    context 'when the file contains other wallet data' do
      let(:initial_seed_data) do
        {
          SecureRandom.uuid => {}
        }
      end
    end

    context 'when the wallet is seedless' do
      let(:seedless_wallet) { described_class.new(model_with_default_address, seed: '') }

      it 'throws an error' do
        expect do
          seedless_wallet.save_seed!(file_path)
        end.to raise_error 'Wallet does not have seed loaded'
      end
    end

    context 'when the file is malformed' do
      let(:file) do
        Tempfile.new.tap do |f|
          f.write('[1, 2, 3]')
          f.rewind
        end
      end

      it 'throws an error' do
        expect do
          wallet.save_seed!(file_path)
        end.to raise_error(ArgumentError)
      end
    end
  end

  describe '#load_seed' do
    let(:address_list_model) do
      Coinbase::Client::AddressList.new(
        data: [address_model1],
        total_count: 1
      )
    end
    let(:seed_wallet) do
      described_class.new(model_with_default_address, seed: seed)
    end
    let(:seedless_wallet) do
      described_class.new(model_with_default_address, seed: '')
    end
    let(:initial_seed_data) do
      {
        wallet_id => {
          seed: seed,
          encrypted: false
        }
      }
    end
    let(:other_seed_data) do
      {
        SecureRandom.uuid => {
          seed: 'other-seed',
          encrypted: false
        }
      }
    end
    let(:malformed_seed_data) do
      {
        wallet_id => 'test'
      }
    end

    let(:configuration) do
      instance_double(
        Coinbase::Configuration,
        use_server_signer: use_server_signer,
        api_client: nil,
        api_key_private_key: OpenSSL::PKey::EC.generate('prime256v1').to_pem
      )
    end

    let(:file) do
      Tempfile.new.tap do |f|
        f.write(JSON.pretty_generate(initial_seed_data))
        f.rewind
      end
    end

    let(:file_path) { file.path }

    before do
      allow(addresses_api)
        .to receive(:list_addresses)
        .with(wallet_id, { limit: 20 })
        .and_return(Coinbase::Client::AddressList.new(data: [address_model1], total_count: 1))
    end

    after { file.unlink }

    it 'loads the seed from the file' do
      seedless_wallet.load_seed(file_path)
      expect(seedless_wallet.can_sign?).to be true
    end

    it 'loads the encrypted seed from the file' do
      seed_wallet.save_seed!(file_path, encrypt: true)
      seedless_wallet.load_seed(file_path)
      expect(seedless_wallet.can_sign?).to be true
    end

    it 'loads the encrypted seed from file with multiple seeds' do
      seed_wallet.save_seed!(file_path, encrypt: true)

      other_model = Coinbase::Client::Wallet.new(id: SecureRandom.uuid, network_id: network_id)
      other_wallet = described_class.new(other_model)
      other_wallet.save_seed!(file_path, encrypt: true)

      seedless_wallet.load_seed(file_path)
      expect(seedless_wallet.can_sign?).to be true
    end

    it 'throws an error when the wallet is already hydrated' do
      expect do
        seed_wallet.load_seed(file_path)
      end.to raise_error('Wallet already has seed loaded')
    end

    context 'when the file contains different wallet data' do
      let(:initial_seed_data) { other_seed_data }

      it 'throws an error when file contains different wallet data' do
        expect do
          seedless_wallet.load_seed(file_path)
        end.to raise_error(ArgumentError, /does not contain seed data for wallet/)
      end
    end

    context 'when the file is empty' do
      let(:file_path) { '/tmp/empty.json' }

      it 'throws an error when the file is absent' do
        expect do
          seedless_wallet.load_seed(file_path)
        end.to raise_error(ArgumentError, /does not contain seed data/)
      end
    end

    context 'when the backup file is corrupted' do
      let(:initial_seed_data) { malformed_seed_data }

      it 'throws an error when the backup file is corrupted' do
        expect do
          seedless_wallet.load_seed(file_path)
        end.to raise_error(ArgumentError, 'Seed data is malformed')
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
        described_class.new(model_with_default_address, seed: '')
      end

      it 'includes the default address' do
        expect(wallet.inspect).to include(address_model1.address_id)
      end
    end
  end
end
