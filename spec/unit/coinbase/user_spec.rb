# frozen_string_literal: true

describe Coinbase::User do
  let(:user_id) { SecureRandom.uuid }
  let(:model) { Coinbase::Client::User.new({ 'id': user_id }) }
  let(:wallets_api) { instance_double(Coinbase::Client::WalletsApi) }
  let(:addresses_api) { instance_double(Coinbase::Client::AddressesApi) }
  let(:user) { described_class.new(model) }
  let(:transfers_api) { instance_double(Coinbase::Client::TransfersApi) }

  describe '#user_id' do
    it 'returns the user ID' do
      expect(user.user_id).to eq(user_id)
    end
  end

  describe '#create_wallet' do
    let(:wallet_id) { SecureRandom.uuid }
    let(:network_id) { 'base-sepolia' }
    let(:create_wallet_request) { { wallet: { network_id: network_id } } }
    let(:opts) { { create_wallet_request: create_wallet_request } }
    let(:wallet_model) { Coinbase::Client::Wallet.new({ 'id': wallet_id, 'network_id': network_id }) }
    let(:wallet_model_with_default_address) do
      Coinbase::Client::Wallet.new(
        {
          'id': wallet_id,
          'network_id': 'base-sepolia',
          'default_address': Coinbase::Client::Address.new({
                                                             'address_id': '0xdeadbeef',
                                                             'wallet_id': wallet_id,
                                                             'public_key': '0x1234567890',
                                                             'network_id': 'base-sepolia'
                                                           })
        }
      )
    end

    before do
      allow(Coinbase::Client::AddressesApi).to receive(:new).and_return(addresses_api)
      allow(Coinbase::Client::WalletsApi).to receive(:new).and_return(wallets_api)
      expect(wallets_api).to receive(:create_wallet).with(opts).and_return(wallet_model)
      expect(addresses_api)
        .to receive(:create_address)
        .with(wallet_id, satisfy do |opts|
          public_key_present = opts[:create_address_request][:public_key].is_a?(String)
          attestation_present = opts[:create_address_request][:attestation].is_a?(String)
          public_key_present && attestation_present
        end)
      expect(wallets_api).to receive(:get_wallet).with(wallet_id).and_return(wallet_model_with_default_address)
    end

    it 'creates a new wallet' do
      wallet = user.create_wallet
      expect(wallet).to be_a(Coinbase::Wallet)
      expect(wallet.wallet_id).to eq(wallet_id)
      expect(wallet.network_id).to eq(:base_sepolia)
    end
  end

  describe '#import_wallet' do
    let(:client) { double('Jimson::Client') }
    let(:wallet_id) { SecureRandom.uuid }
    let(:wallet_model) { Coinbase::Client::Wallet.new({ 'id': wallet_id, 'network_id': 'base-sepolia' }) }
    let(:wallets_api) { double('Coinbase::Client::WalletsApi') }
    let(:network_id) { 'base-sepolia' }
    let(:create_wallet_request) { { wallet: { network_id: network_id } } }
    let(:opts) { { create_wallet_request: create_wallet_request } }
    let(:addresses_api) { double('Coinbase::Client::AddressesApi') }
    let(:address_model) do
      Coinbase::Client::Address.new({
                                      'address_id': '0xdeadbeef',
                                      'wallet_id': wallet_id,
                                      'public_key': '0x1234567890',
                                      'network_id': 'base-sepolia'
                                    })
    end
    let(:wallet_model_with_default_address) do
      Coinbase::Client::Wallet.new(
        {
          'id': wallet_id,
          'network_id': 'base-sepolia',
          'default_address': address_model
        }
      )
    end
    let(:address_list_model) do
      Coinbase::Client::AddressList.new({ 'data' => [address_model], 'total_count' => 1 })
    end
    let(:wallet_export_data) do
      Coinbase::Wallet::Data.new(
        wallet_id: wallet_id,
        seed: MoneyTree::Master.new.seed_hex
      )
    end
    subject(:imported_wallet) { user.import_wallet(wallet_export_data) }

    before do
      allow(Coinbase::Client::AddressesApi).to receive(:new).and_return(addresses_api)
      allow(Coinbase::Client::WalletsApi).to receive(:new).and_return(wallets_api)
      expect(wallets_api).to receive(:get_wallet).with(wallet_id).and_return(wallet_model_with_default_address)
      expect(addresses_api).to receive(:list_addresses).with(wallet_id).and_return(address_list_model)
      expect(addresses_api).to receive(:get_address).and_return(address_model)
    end

    it 'imports an exported wallet' do
      expect(imported_wallet.wallet_id).to eq(wallet_id)
    end

    it 'loads the wallet addresses' do
      expect(imported_wallet.list_addresses.length).to eq(address_list_model.total_count)
    end

    it 'contains the same seed when re-exported' do
      expect(imported_wallet.export.seed).to eq(wallet_export_data.seed)
    end
  end

  describe '#list_wallet_ids' do
    let(:wallet_ids) { [SecureRandom.uuid, SecureRandom.uuid] }
    let(:data) do
      wallet_ids.map { |id| Coinbase::Client::Wallet.new({ 'id': id, 'network_id': 'base-sepolia' }) }
    end
    let(:wallet_list) { Coinbase::Client::WalletList.new({ 'data' => data }) }
    it 'lists the wallet IDs' do
      allow(Coinbase::Client::WalletsApi).to receive(:new).and_return(wallets_api)
      expect(wallets_api).to receive(:list_wallets).and_return(wallet_list)
      expect(user.list_wallet_ids).to eq(wallet_ids)
    end
  end

  describe '#save_wallet' do
    let(:seed) { '86fc9fba421dcc6ad42747f14132c3cd975bd9fb1454df84ce5ea554f2542fbe' }
    let(:address_count) { 1 }
    let(:seed_wallet) do
      Coinbase::Wallet.new(model, seed: seed, address_count: address_count)
    end
    let(:user) { described_class.new(model) }
    Coinbase.configuration.backup_file_path = "#{SecureRandom.uuid}.json"
    Coinbase.configuration.api_key_private_key = OpenSSL::PKey::EC.generate('prime256v1').to_pem
    let(:wallet_id) { SecureRandom.uuid }
    let(:addresses_api) { double('Coinbase::Client::AddressesApi') }
    let(:address_model) do
      Coinbase::Client::Address.new({
                                      'address_id': '0xdeadbeef',
                                      'wallet_id': wallet_id,
                                      'public_key': '0x1234567890',
                                      'network_id': 'base-sepolia'
                                    })
    end
    let(:initial_seed_data) { JSON.pretty_generate({}) }
    let(:expected_seed_data) {
      {
        seed_wallet.wallet_id => {
          seed: seed,
          encrypted: false
        }
      }
    }

    before do
      allow(Coinbase::Client::AddressesApi).to receive(:new).and_return(addresses_api)
      expect(addresses_api).to receive(:get_address).and_return(address_model)
      File.open(Coinbase.configuration.backup_file_path, 'w') do |file|
        file.write(initial_seed_data)
      end
    end
    after do
      File.delete(Coinbase.configuration.backup_file_path)
    end

    it 'saves the Wallet data when encryption is false' do
      user.save_wallet(seed_wallet)
      # Verify that the file has new wallet.
      stored_seed_data = File.read(Coinbase.configuration.backup_file_path)
      wallets = JSON.parse(stored_seed_data)
      data = wallets[seed_wallet.wallet_id]
      expect(data).not_to be_empty
      expect(data['encrypted']).to eq(false)
      expect(data['iv']).to eq('')
      expect(data['auth_tag']).to eq('')
      expect(data['seed']).to eq(seed)
    end

    it 'saves the Wallet data when encryption is true' do
      user.save_wallet(seed_wallet, true)
      # Verify that the file has new wallet.
      stored_seed_data = File.read(Coinbase.configuration.backup_file_path)
      wallets = JSON.parse(stored_seed_data)
      data = wallets[seed_wallet.wallet_id]
      expect(data).not_to be_empty
      expect(data['encrypted']).to eq(true)
      expect(data['iv']).not_to be_empty
      expect(data['auth_tag']).not_to be_empty
      expect(data['seed']).not_to eq(seed)
    end

    it 'it creates a new file and saves the wallet when the file does not exist' do
      File.delete(Coinbase.configuration.backup_file_path)
      user.save_wallet(seed_wallet)
      stored_seed_data = File.read(Coinbase.configuration.backup_file_path)
      wallets = JSON.parse(stored_seed_data)
      data = wallets[seed_wallet.wallet_id]
      expect(data).not_to be_empty
      expect(data['encrypted']).to eq(false)
    end

    it 'it throws an error when the existing file is malformed' do
      File.open(Coinbase.configuration.backup_file_path, 'w') do |file|
        file.write(JSON.pretty_generate({
          malformed: 'test'
        }.to_json))
      end
      expect do
        user.save_wallet(seed_wallet)
      end.to raise_error(ArgumentError, 'Malformed backup data')
    end
  end

  describe '#load_wallets' do
    let(:seed) { '86fc9fba421dcc6ad42747f14132c3cd975bd9fb1454df84ce5ea554f2542fbe' }
    let(:address_count) { 1 }
    let(:seed_wallet) do
      Coinbase::Wallet.new(model, seed: seed, address_count: address_count)
    end
    let(:user) { described_class.new(model) }
    Coinbase.configuration.backup_file_path = "#{SecureRandom.uuid}.json"
    Coinbase.configuration.api_key_private_key = OpenSSL::PKey::EC.generate('prime256v1').to_pem
    let(:wallet_id) { SecureRandom.uuid }
    let(:addresses_api) { double('Coinbase::Client::AddressesApi') }
    let(:address_model) do
      Coinbase::Client::Address.new({
                                      'address_id': '0xdeadbeef',
                                      'wallet_id': wallet_id,
                                      'public_key': '0x1234567890',
                                      'network_id': 'base-sepolia'
                                    })
    end
    let(:wallet_model_with_default_address) do
      Coinbase::Client::Wallet.new(
        {
          'id': wallet_id,
          'network_id': 'base-sepolia',
          'default_address': address_model
        }
      )
    end
    let(:address_list_model) do
      Coinbase::Client::AddressList.new({ 'data' => [address_model], 'total_count' => 1 })
    end
    let(:initial_seed_data) {
      {
        wallet_id => {
          seed: seed,
          encrypted: false
        }
      }
    }
    let(:malformed_seed_data) {
      {
        wallet_id => 'test'
      }
    }
    let(:seed_data_without_seed) {
      {
        wallet_id => {
          seed: '',
          encrypted: false
        }
      }
    }
    let(:seed_data_without_iv) {
      {
        wallet_id => {
          seed: seed,
          encrypted: true,
          iv: '',
          auth_tag: '0x111'
        }
      }
    }
    let(:seed_data_without_auth_tag) {
      {
        wallet_id => {
          seed: seed,
          encrypted: true,
          iv: '0x111',
          auth_tag: ''
        }
      }
    }

    before do
      File.open(Coinbase.configuration.backup_file_path, 'w') do |file|
        file.write(JSON.pretty_generate(initial_seed_data))
      end
    end
    after do
      File.delete(Coinbase.configuration.backup_file_path) if File.exist?(Coinbase.configuration.backup_file_path)
    end

    it 'loads the Wallet from backup' do
      allow(Coinbase::Client::AddressesApi).to receive(:new).and_return(addresses_api)
      allow(Coinbase::Client::WalletsApi).to receive(:new).and_return(wallets_api)
      expect(wallets_api).to receive(:get_wallet).with(wallet_id).and_return(wallet_model_with_default_address)
      expect(addresses_api).to receive(:list_addresses).with(wallet_id).and_return(address_list_model)
      expect(addresses_api).to receive(:get_address).and_return(address_model)

      wallets = user.load_wallets
      wallet = wallets[wallet_id]
      expect(wallet).not_to be_nil
      expect(wallet.wallet_id).to eq(wallet_id)
      expect(wallet.default_address.address_id).to eq(address_model.address_id)
    end

    it 'throws an error when the backup file is absent' do
      File.delete(Coinbase.configuration.backup_file_path)
      expect do
        user.load_wallets
      end.to raise_error(ArgumentError, 'Backup file not found')
    end

    it 'throws an error when the backup file is corrupted' do
      File.open(Coinbase.configuration.backup_file_path, 'w') do |file|
        file.write(JSON.pretty_generate(malformed_seed_data))
      end
      expect do
        user.load_wallets
      end.to raise_error(ArgumentError, 'Malformed backup data')
    end

    it 'throws an error when backup does not contain seed' do
      # Delete the existing file and write a new malformed file.
      File.delete(Coinbase.configuration.backup_file_path) if File.exist?(Coinbase.configuration.backup_file_path)

      File.open(Coinbase.configuration.backup_file_path, 'w') do |file|
        file.write(JSON.pretty_generate(seed_data_without_seed))
      end
      expect do
        user.load_wallets
      end.to raise_error(ArgumentError, 'Malformed backup data')
    end

    it 'throws an error when backup does not contain iv' do
      # Delete the existing file and write a new malformed file.
      File.delete(Coinbase.configuration.backup_file_path) if File.exist?(Coinbase.configuration.backup_file_path)

      File.open(Coinbase.configuration.backup_file_path, 'w') do |file|
        file.write(JSON.pretty_generate(seed_data_without_iv))
      end
      expect do
        user.load_wallets
      end.to raise_error(ArgumentError, 'Malformed encrypted seed data')
    end

    it 'throws an error when backup does not contain auth_tag' do
      # Delete the existing file and write a new malformed file.
      File.delete(Coinbase.configuration.backup_file_path) if File.exist?(Coinbase.configuration.backup_file_path)

      File.open(Coinbase.configuration.backup_file_path, 'w') do |file|
        file.write(JSON.pretty_generate(seed_data_without_auth_tag))
      end
      expect do
        user.load_wallets
      end.to raise_error(ArgumentError, 'Malformed encrypted seed data')
    end
  end
end
