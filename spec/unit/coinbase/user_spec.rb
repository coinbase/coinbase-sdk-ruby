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
      expect(wallets_api).to receive(:get_wallet).with(wallet_id).and_return(wallet_model)
      expect(addresses_api).to receive(:list_addresses).with(wallet_id).and_return(address_list_model)
      expect(addresses_api).to receive(:get_address).and_return(address_model)
    end

    it 'imports an exported Wallet' do
      wallet = user.create_wallet
      data = wallet.export
      new_wallet = user.import_wallet(data)

      expect(new_wallet.wallet_id).to eq(wallet.wallet_id)
      expect(new_wallet.list_addresses.length).to eq(wallet.list_addresses.length)
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
end
