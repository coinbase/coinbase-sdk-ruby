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

  describe '#configure_from_json' do
    let(:file_path) { 'spec/fixtures/cdp_api_key.json' }

    subject do
      Coinbase.configure_from_json(file_path)
    end

    it 'correctly configures the API key' do
      expect { subject }.not_to raise_error
      expect(Coinbase.configuration.api_key_private_key).not_to be_nil
      expect(Coinbase.configuration.api_key_name).not_to be_nil
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

  describe '#call_api' do
    context 'when the API call is successful' do
      it 'does not raise an error' do
        expect do
          Coinbase.call_api { 'success' }
        end.not_to raise_error
      end
    end

    context 'when the API call raises a standard error' do
      it 'raises the standard error' do
        expect do
          Coinbase.call_api { raise StandardError, 'error' }
        end.to raise_error('error')
      end
    end

    context 'when the API call raises an API error' do
      let(:err) do
        Coinbase::Client::ApiError.new(
          code: 501,
          response_body: '{ "code": "unimplemented", "message": "method is not implemented"}'
        )
      end

      it 'raises the appropriate API error' do
        expect do
          Coinbase.call_api { raise err }
        end.to raise_error(Coinbase::UnimplementedError)
      end
    end
  end

  describe Coinbase::Configuration do
    describe '#api_url' do
      it 'returns the default api url' do
        expect(Coinbase.configuration.api_url).to eq 'https://api.cdp.coinbase.com'
      end
    end
  end
end
