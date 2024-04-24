# frozen_string_literal: true

describe Coinbase::User do
  let(:user_id) { SecureRandom.uuid }
  let(:delegate) { Coinbase::Client::User.new({ 'id': user_id }) }
  let(:wallets_api) { instance_double(Coinbase::Client::WalletsApi) }
  let(:user) { described_class.new(delegate, wallets_api) }

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
    let(:wallet_delegate) { Coinbase::Client::Wallet.new({ 'id': wallet_id, 'network_id': network_id }) }

    before do
      expect(wallets_api).to receive(:create_wallet).with(opts).and_return(wallet_delegate)
    end

    it 'creates a new wallet' do
      wallet = user.create_wallet
      expect(wallet).to be_a(Coinbase::Wallet)
      expect(wallet.wallet_id).to eq(wallet_id)
      expect(wallet.network_id).to eq(:base_sepolia)
    end
  end

  describe '#list_wallets' do
    it 'lists the wallets belonging to the user' do
      expect { user.list_wallets }.to raise_error(NotImplementedError)
    end
  end

  describe '#get_wallet' do
    it 'returns the wallet with the given ID' do
      expect { user.get_wallet(SecureRandom.uuid) }.to raise_error(NotImplementedError)
    end
  end
end
