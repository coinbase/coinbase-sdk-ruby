# frozen_string_literal: true

describe Coinbase::User do
  let(:user_id) { SecureRandom.uuid }
  let(:model) { Coinbase::Client::User.new({ 'id': user_id }) }
  let(:wallets_api) { instance_double(Coinbase::Client::WalletsApi) }
  let(:addresses_api) { instance_double(Coinbase::Client::AddressesApi) }
  let(:transfers_api) { instance_double(Coinbase::Client::TransfersApi) }
  subject(:user) { described_class.new(model) }

  describe '#id' do
    it 'returns the user ID' do
      expect(user.id).to eq(user_id)
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
      expect(wallet.id).to eq(wallet_id)
      expect(wallet.network_id).to eq(:base_sepolia)
    end
  end

  describe '#import_wallet' do
    let(:wallet_export_data) do
      Coinbase::Wallet::Data.new(
        wallet_id: SecureRandom.uuid,
        seed: MoneyTree::Master.new.seed_hex
      )
    end
    let(:wallet) { instance_double(Coinbase::Wallet) }
    subject(:imported_wallet) { user.import_wallet(wallet_export_data) }

    it 'imports an exported wallet' do
      allow(Coinbase::Wallet).to receive(:import).with(wallet_export_data).and_return(wallet)

      expect(user.import_wallet(wallet_export_data)).to eq(wallet)
    end
  end

  describe '#wallets' do
    let(:page_size) { 20 }
    let(:next_page_token) { SecureRandom.uuid }
    let(:wallet_model1) { Coinbase::Client::Wallet.new({ 'id': 'wallet1', 'network_id': 'base-sepolia' }) }
    let(:wallet_model2) { Coinbase::Client::Wallet.new({ 'id': 'wallet2', 'network_id': 'base-sepolia' }) }
    let(:address_model1) do
      Coinbase::Client::Address.new({
                                      'address_id': '0xdeadbeef1',
                                      'wallet_id': 'wallet1',
                                      'public_key': '0x1234567890',
                                      'network_id': 'base-sepolia'
                                    })
    end
    let(:address_model2) do
      Coinbase::Client::Address.new({
                                      'address_id': '0xdeadbeef2',
                                      'wallet_id': 'wallet1',
                                      'public_key': '0x1234567890',
                                      'network_id': 'base-sepolia'
                                    })
    end
    let(:address_model3) do
      Coinbase::Client::Address.new({
                                      'address_id': '0xdeadbeef3',
                                      'wallet_id': 'wallet2',
                                      'public_key': '0x1234567890',
                                      'network_id': 'base-sepolia'
                                    })
    end
    let(:address_model4) do
      Coinbase::Client::Address.new({
                                      'address_id': '0xdeadbeef4',
                                      'wallet_id': 'wallet2',
                                      'public_key': '0x1234567890',
                                      'network_id': 'base-sepolia'
                                    })
    end

    before do
      allow(Coinbase::Client::AddressesApi).to receive(:new).and_return(addresses_api)
      allow(Coinbase::Client::WalletsApi).to receive(:new).and_return(wallets_api)
      expect(wallets_api)
        .to receive(:list_wallets)
        .and_return(
          Coinbase::Client::WalletList.new({ 'data' => [wallet_model1, wallet_model2], 'total_count' => 2 })
        )
      expect(addresses_api)
        .to receive(:list_addresses)
        .with('wallet1', { limit: Coinbase::Wallet::MAX_ADDRESSES })
        .and_return(
          Coinbase::Client::AddressList.new({ 'data' => [address_model1, address_model2], 'total_count' => 2 })
        )
      expect(addresses_api)
        .to receive(:list_addresses)
        .with('wallet2', { limit: Coinbase::Wallet::MAX_ADDRESSES })
        .and_return(
          Coinbase::Client::AddressList.new({ 'data' => [address_model3, address_model4], 'total_count' => 2 })
        )
    end

    it 'returns all wallets' do
      wallets = user.wallets
      expect(wallets.size).to eq(2)
      expect(wallets[0].id).to eq(wallet_model1.id)
      expect(wallets[1].id).to eq(wallet_model2.id)
    end
  end

  describe '#save_wallet_locally!' do
    let(:seed) { '86fc9fba421dcc6ad42747f14132c3cd975bd9fb1454df84ce5ea554f2542fbe' }
    let(:address_model) do
      Coinbase::Client::Address.new({
                                      'address_id': '0xfbd9D61057eC1debCeEE12C62812Fb3E1d025201',
                                      'wallet_id': wallet_id,
                                      'public_key': '0x1234567890',
                                      'network_id': 'base-sepolia'
                                    })
    end
    let(:wallet_id) { SecureRandom.uuid }
    let(:seed_wallet) do
      Coinbase::Wallet.new(model, seed: seed, address_models: [address_model])
    end
    let(:user) { described_class.new(model) }
    let(:addresses_api) { double('Coinbase::Client::AddressesApi') }

    let(:initial_seed_data) { JSON.pretty_generate({}) }
    let(:expected_seed_data) do
      {
        seed_wallet.id => {
          seed: seed,
          encrypted: false
        }
      }
    end

    before do
      @backup_file_path = Coinbase.configuration.backup_file_path
      @api_key_private_key = Coinbase.configuration.api_key_private_key
      Coinbase.configuration.backup_file_path = "#{SecureRandom.uuid}.json"
      Coinbase.configuration.api_key_private_key = OpenSSL::PKey::EC.generate('prime256v1').to_pem
      allow(Coinbase::Client::AddressesApi).to receive(:new).and_return(addresses_api)
      File.open(Coinbase.configuration.backup_file_path, 'w') do |file|
        file.write(initial_seed_data)
      end
    end

    after do
      File.delete(Coinbase.configuration.backup_file_path)
      Coinbase.configuration.backup_file_path = @backup_file_path
      Coinbase.configuration.api_key_private_key = @api_key_private_key
    end

    it 'saves the Wallet data when encryption is false' do
      saved_wallet = user.save_wallet_locally!(seed_wallet)
      # Verify that the file has new wallet.
      stored_seed_data = File.read(Coinbase.configuration.backup_file_path)
      wallets = JSON.parse(stored_seed_data)
      data = wallets[seed_wallet.id]
      expect(data).not_to be_empty
      expect(data['encrypted']).to eq(false)
      expect(data['iv']).to eq('')
      expect(data['auth_tag']).to eq('')
      expect(data['seed']).to eq(seed)
      expect(saved_wallet).to eq(seed_wallet)
    end

    it 'saves the Wallet data when encryption is true' do
      saved_wallet = user.save_wallet_locally!(seed_wallet, encrypt: true)
      # Verify that the file has new wallet.
      stored_seed_data = File.read(Coinbase.configuration.backup_file_path)
      wallets = JSON.parse(stored_seed_data)
      data = wallets[seed_wallet.id]
      expect(data).not_to be_empty
      expect(data['encrypted']).to eq(true)
      expect(data['iv']).not_to be_empty
      expect(data['auth_tag']).not_to be_empty
      expect(data['seed']).not_to eq(seed)
      expect(saved_wallet).to eq(seed_wallet)
    end

    it 'it creates a new file and saves the wallet when the file does not exist' do
      File.delete(Coinbase.configuration.backup_file_path)
      saved_wallet = user.save_wallet_locally!(seed_wallet)
      stored_seed_data = File.read(Coinbase.configuration.backup_file_path)
      wallets = JSON.parse(stored_seed_data)
      data = wallets[seed_wallet.id]
      expect(data).not_to be_empty
      expect(data['encrypted']).to eq(false)
      expect(saved_wallet).to eq(seed_wallet)
    end

    it 'it throws an error when the existing file is malformed' do
      File.open(Coinbase.configuration.backup_file_path, 'w') do |file|
        file.write(JSON.pretty_generate({
          malformed: 'test'
        }.to_json))
      end
      expect do
        user.save_wallet_locally!(seed_wallet)
      end.to raise_error(ArgumentError, 'Malformed backup data')
    end
  end

  describe '#load_wallets_from_local' do
    let(:seed) { '86fc9fba421dcc6ad42747f14132c3cd975bd9fb1454df84ce5ea554f2542fbe' }
    let(:address_count) { 1 }
    let(:wallet_id) { SecureRandom.uuid }
    let(:address_model) do
      Coinbase::Client::Address.new({
                                      'address_id': '0xfbd9D61057eC1debCeEE12C62812Fb3E1d025201',
                                      'wallet_id': wallet_id,
                                      'public_key': '0x1234567890',
                                      'network_id': 'base-sepolia'
                                    })
    end
    let(:seed_wallet) do
      Coinbase::Wallet.new(model, seed: seed, address_models: [address_model])
    end
    let(:user) { described_class.new(model) }
    let(:addresses_api) { double('Coinbase::Client::AddressesApi') }
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
    let(:initial_seed_data) do
      {
        wallet_id => {
          seed: seed,
          encrypted: false
        }
      }
    end
    let(:malformed_seed_data) do
      {
        wallet_id => 'test'
      }
    end
    let(:seed_data_without_seed) do
      {
        wallet_id => {
          seed: '',
          encrypted: false
        }
      }
    end
    let(:seed_data_without_iv) do
      {
        wallet_id => {
          seed: seed,
          encrypted: true,
          iv: '',
          auth_tag: '0x111'
        }
      }
    end
    let(:seed_data_without_auth_tag) do
      {
        wallet_id => {
          seed: seed,
          encrypted: true,
          iv: '0x111',
          auth_tag: ''
        }
      }
    end

    before do
      @backup_file_path = Coinbase.configuration.backup_file_path
      @api_key_private_key = Coinbase.configuration.api_key_private_key
      Coinbase.configuration.backup_file_path = "#{SecureRandom.uuid}.json"
      Coinbase.configuration.api_key_private_key = OpenSSL::PKey::EC.generate('prime256v1').to_pem
      File.open(Coinbase.configuration.backup_file_path, 'w') do |file|
        file.write(JSON.pretty_generate(initial_seed_data))
      end
    end
    after do
      File.delete(Coinbase.configuration.backup_file_path) if File.exist?(Coinbase.configuration.backup_file_path)
      Coinbase.configuration.backup_file_path = @backup_file_path
      Coinbase.configuration.api_key_private_key = @api_key_private_key
    end

    it 'loads the Wallet from backup' do
      allow(Coinbase::Client::AddressesApi).to receive(:new).and_return(addresses_api)
      allow(Coinbase::Client::WalletsApi).to receive(:new).and_return(wallets_api)
      expect(wallets_api).to receive(:get_wallet).with(wallet_id).and_return(wallet_model_with_default_address)
      expect(addresses_api)
        .to receive(:list_addresses)
        .with(wallet_id, { limit: Coinbase::Wallet::MAX_ADDRESSES })
        .and_return(address_list_model)

      wallets = user.load_wallets_from_local
      wallet = wallets[wallet_id]
      expect(wallet).not_to be_nil
      expect(wallet.id).to eq(wallet_id)
      expect(wallet.default_address.id).to eq(address_model.address_id)
    end

    it 'throws an error when the backup file is absent' do
      File.delete(Coinbase.configuration.backup_file_path)
      expect do
        user.load_wallets_from_local
      end.to raise_error(ArgumentError, 'Backup file not found')
    end

    it 'throws an error when the backup file is corrupted' do
      File.open(Coinbase.configuration.backup_file_path, 'w') do |file|
        file.write(JSON.pretty_generate(malformed_seed_data))
      end
      expect do
        user.load_wallets_from_local
      end.to raise_error(ArgumentError, 'Malformed backup data')
    end

    it 'throws an error when backup does not contain seed' do
      # Delete the existing file and write a new malformed file.
      File.delete(Coinbase.configuration.backup_file_path) if File.exist?(Coinbase.configuration.backup_file_path)

      File.open(Coinbase.configuration.backup_file_path, 'w') do |file|
        file.write(JSON.pretty_generate(seed_data_without_seed))
      end
      expect do
        user.load_wallets_from_local
      end.to raise_error(ArgumentError, 'Malformed backup data')
    end

    it 'throws an error when backup does not contain iv' do
      # Delete the existing file and write a new malformed file.
      File.delete(Coinbase.configuration.backup_file_path) if File.exist?(Coinbase.configuration.backup_file_path)

      File.open(Coinbase.configuration.backup_file_path, 'w') do |file|
        file.write(JSON.pretty_generate(seed_data_without_iv))
      end
      expect do
        user.load_wallets_from_local
      end.to raise_error(ArgumentError, 'Malformed encrypted seed data')
    end

    it 'throws an error when backup does not contain auth_tag' do
      # Delete the existing file and write a new malformed file.
      File.delete(Coinbase.configuration.backup_file_path) if File.exist?(Coinbase.configuration.backup_file_path)

      File.open(Coinbase.configuration.backup_file_path, 'w') do |file|
        file.write(JSON.pretty_generate(seed_data_without_auth_tag))
      end
      expect do
        user.load_wallets_from_local
      end.to raise_error(ArgumentError, 'Malformed encrypted seed data')
    end
  end

  describe '#inspect' do
    it 'includes user details' do
      expect(user.inspect).to include(user_id)
    end

    it 'returns the same value as to_s' do
      expect(user.inspect).to eq(user.to_s)
    end
  end
end
