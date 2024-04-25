# frozen_string_literal: true

describe Coinbase::User do
  let(:user_id) { SecureRandom.uuid }
  let(:model) { Coinbase::Client::User.new({ 'id': user_id }) }
  let(:wallets_api) { instance_double(Coinbase::Client::WalletsApi) }
  let(:addresses_api) { instance_double(Coinbase::Client::AddressesApi) }
  let(:user) { described_class.new(model, wallets_api, addresses_api) }

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

    before do
      expect(wallets_api).to receive(:create_wallet).with(opts).and_return(wallet_model)
      expect(addresses_api)
        .to receive(:create_address)
        .with(wallet_id, satisfy do |opts|
          public_key_present = opts[:create_address_request][:public_key].is_a?(String)
          attestation_present = opts[:create_address_request][:attestation].is_a?(String)
          public_key_present && attestation_present
        end)
    end

    it 'creates a new wallet' do
      wallet = user.create_wallet
      expect(wallet).to be_a(Coinbase::Wallet)
      expect(wallet.wallet_id).to eq(wallet_id)
      expect(wallet.network_id).to eq(:base_sepolia)
    end
  end

  describe '#import_wallet' do
    let(:wallet_id) { SecureRandom.uuid }
    let(:seed) { '000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f' }
    let(:address_count) { 2 }
    let(:data) { Coinbase::Wallet::Data.new(wallet_id, seed) }
    let(:wallet_model) { Coinbase::Client::Wallet.new({ 'id': wallet_id, 'network_id': 'base-sepolia' }) }
    let(:address_list_model) { Coinbase::Client::AddressList.new({ 'total_count': address_count }) }

    before do
      expect(wallets_api).to receive(:get_wallet).with(wallet_id).and_return(wallet_model)
      expect(addresses_api).to receive(:list_addresses).and_return(address_list_model)
      expect(addresses_api).to receive(:get_address).exactly(address_count).times
    end

    it 'imports a wallet' do
      wallet = user.import_wallet(data)
      expect(wallet).to be_a(Coinbase::Wallet)
      expect(wallet.wallet_id).to eq(wallet_id)
      expect(wallet.network_id).to eq(:base_sepolia)
      expect(wallet.list_addresses.length).to eq(address_count)
    end
  end

  describe '#list_wallet_ids' do
    let(:wallet_ids) { [SecureRandom.uuid, SecureRandom.uuid] }
    let(:data) do
      wallet_ids.map { |id| Coinbase::Client::Wallet.new({ 'id': id, 'network_id': 'base-sepolia' }) }
    end
    let(:wallet_list) { Coinbase::Client::WalletList.new({ 'data' => data }) }
    it 'lists the wallet IDs' do
      expect(wallets_api).to receive(:list_wallets).and_return(wallet_list)
      expect(user.list_wallet_ids).to eq(wallet_ids)
    end
  end
end
