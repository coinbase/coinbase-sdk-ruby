# frozen_string_literal: true

describe Coinbase::User do
  let(:user_id) { SecureRandom.uuid }
  let(:model) { Coinbase::Client::User.new({ id: user_id }) }
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
    let(:network_id) { 'base-sepolia' }
    let(:wallet) { instance_double('Coinbase::Wallet', network_id: Coinbase.to_sym(network_id)) }

    context 'when called with no arguments' do
      before do
        allow(Coinbase::Wallet).to receive(:create).with(no_args).and_return(wallet)
      end

      it 'creates a new wallet' do
        expect(user.create_wallet).to eq(wallet)
      end
    end

    context 'when called with a specified network ID' do
      before do
        allow(Coinbase::Wallet).to receive(:create).with(network_id: network_id).and_return(wallet)
      end

      it 'creates a new wallet for the specified network ID' do
        expect(user.create_wallet(network_id: network_id)).to eq(wallet)
      end
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
    let(:wallet_model1) { Coinbase::Client::Wallet.new({ id: 'wallet1', network_id: 'base-sepolia' }) }
    let(:wallet_model2) { Coinbase::Client::Wallet.new({ id: 'wallet2', network_id: 'base-sepolia' }) }
    let(:address_model1) do
      Coinbase::Client::Address.new({
                                      address_id: '0xdeadbeef1',
                                      wallet_id: 'wallet1',
                                      public_key: '0x1234567890',
                                      network_id: 'base-sepolia'
                                    })
    end
    let(:address_model2) do
      Coinbase::Client::Address.new({
                                      address_id: '0xdeadbeef2',
                                      wallet_id: 'wallet1',
                                      public_key: '0x1234567890',
                                      network_id: 'base-sepolia'
                                    })
    end
    let(:address_model3) do
      Coinbase::Client::Address.new({
                                      address_id: '0xdeadbeef3',
                                      wallet_id: 'wallet2',
                                      public_key: '0x1234567890',
                                      network_id: 'base-sepolia'
                                    })
    end
    let(:address_model4) do
      Coinbase::Client::Address.new({
                                      address_id: '0xdeadbeef4',
                                      wallet_id: 'wallet2',
                                      public_key: '0x1234567890',
                                      network_id: 'base-sepolia'
                                    })
    end

    before do
      allow(Coinbase::Client::AddressesApi).to receive(:new).and_return(addresses_api)
      allow(Coinbase::Client::WalletsApi).to receive(:new).and_return(wallets_api)
      expect(wallets_api)
        .to receive(:list_wallets)
        .and_return(
          Coinbase::Client::WalletList.new(
            {
              'data' => [wallet_model1, wallet_model2],
              'next_page' => 'next_page_token',
              'total_count' => 2
            }
          )
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
      wallets, next_page_token = user.wallets
      expect(wallets.size).to eq(2)
      expect(wallets[0].id).to eq(wallet_model1.id)
      expect(wallets[1].id).to eq(wallet_model2.id)
      expect(next_page_token).to eq('next_page_token')
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
