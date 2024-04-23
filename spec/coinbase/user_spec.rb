# frozen_string_literal: true

describe Coinbase::User do
  let(:user_id) { SecureRandom.uuid }
  let(:delegate) { Coinbase::Client::User.new({ 'id': user_id }) }
  let(:user) { described_class.new(delegate) }

  describe '#user_id' do
    it 'returns the user ID' do
      expect(user.user_id).to eq(user_id)
    end
  end

  describe '#create_wallet' do
    it 'creates a new wallet' do
      wallet = user.create_wallet
      expect(wallet).to be_a(Coinbase::Wallet)
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
