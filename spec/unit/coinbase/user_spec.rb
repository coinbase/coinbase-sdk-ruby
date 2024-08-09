# frozen_string_literal: true

describe Coinbase::User do
  subject(:user) { described_class.new(model) }

  let(:user_id) { SecureRandom.uuid }
  let(:model) { Coinbase::Client::User.new(id: user_id) }
  let(:wallets_api) { instance_double(Coinbase::Client::WalletsApi) }
  let(:addresses_api) { instance_double(Coinbase::Client::AddressesApi) }
  let(:transfers_api) { instance_double(Coinbase::Client::TransfersApi) }

  describe '#id' do
    it 'returns the user ID' do
      expect(user.id).to eq(user_id)
    end
  end

  describe '#create_wallet' do
    let(:network_id) { 'base-sepolia' }
    let(:wallet) { instance_double(Coinbase::Wallet, network_id: Coinbase.to_sym(network_id)) }

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
    subject(:imported_wallet) { user.import_wallet(wallet_export_data) }

    let(:seed) { MoneyTree::Master.new.seed_hex }
    let(:wallet_id) { SecureRandom.uuid }
    let(:wallet_export_data) { Coinbase::Wallet::Data.new(wallet_id: wallet_id, seed: seed) }
    let(:wallet) { build(:wallet, id: wallet_id, seed: seed) }

    it 'imports an exported wallet' do
      allow(Coinbase::Wallet).to receive(:import).with(wallet_export_data).and_return(wallet)

      expect(user.import_wallet(wallet_export_data)).to eq(wallet)
    end
  end

  describe '#wallets' do
    let(:first_wallet) { build(:wallet_model, :without_default_address, id: 'wallet-1') }
    let(:second_wallet) { build(:wallet_model, :without_default_address, id: 'wallet-2') }
    let(:wallet_enumerator) do
      Enumerator.new do |yielder|
        yielder << first_wallet
        yielder << second_wallet
      end
    end

    before do
      allow(Coinbase::Wallet).to receive(:list).and_return(wallet_enumerator)
    end

    it 'returns a wallet enumerator' do
      expect(user.wallets).to eq(wallet_enumerator)
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
