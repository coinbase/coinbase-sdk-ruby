# frozen_string_literal: true

describe Coinbase do
  describe '#configure' do
    let(:api_key_private_key) { 'some-key' }
    let(:api_key_name) { 'some-key-name' }

    subject do
      Coinbase.configure do |config|
        config.api_key_private_key = api_key_private_key
        config.api_key_name = api_key_name
      end
    end

    context 'when api_key_private_key is nil' do
      let(:api_key_private_key) { nil }
      it 'raises an exception' do
        expect { subject }.to raise_error(Coinbase::InvalidConfiguration, /API key private key/)
      end
    end

    context 'when api_key_name is nil' do
      let(:api_key_name) { nil }
      it 'raises an exception' do
        expect { subject }.to raise_error(Coinbase::InvalidConfiguration, /API key name/)
      end
    end
  end

  describe '#default_user' do
    let(:users_api) { double Coinbase::Client::UsersApi }
    let(:user_model) { double 'User Model' }

    before(:each) do
      allow(Coinbase::Client::UsersApi).to receive(:new).and_return(users_api)
      allow(users_api).to receive(:get_current_user).and_return(user_model)
      allow(Coinbase::User).to receive(:new)
    end

    it 'creates a new users api client' do
      Coinbase.default_user
      expect(Coinbase::Client::UsersApi).to have_received(:new).with(Coinbase.configuration.api_client)
    end

    it 'gets the current user from the api' do
      Coinbase.default_user
      expect(users_api).to have_received(:get_current_user)
    end

    it 'creates a new user object from the response' do
      Coinbase.default_user
      expect(Coinbase::User).to have_received(:new).with(user_model)
    end
  end

  describe Coinbase::Configuration do
    describe '#api_url' do
      it 'returns the default api url' do
        expect(Coinbase.configuration.api_url).to eq 'https://api.cdp.coinbase.com'
      end
    end

    describe '#base_sepolia_rpc_url' do
      it 'returns the default base sepolia rpc url' do
        expect(Coinbase.configuration.base_sepolia_rpc_url).to eq 'https://sepolia.base.org'
      end
    end
  end
end
