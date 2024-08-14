# frozen_string_literal: true

describe Coinbase do
  let(:config) { Coinbase::Configuration.new }

  before do
    allow(described_class).to receive(:configuration).and_return(config)
  end

  describe '#configure' do
    subject(:configure) do
      described_class.configure do |config|
        config.api_key_private_key = api_key_private_key
        config.api_key_name = api_key_name
      end
    end

    let(:api_key_private_key) { 'some-key' }
    let(:api_key_name) { 'some-key-name' }
    let(:server_signer) { false }

    context 'when api_key_private_key is nil' do
      let(:api_key_private_key) { nil }

      it 'raises an exception' do
        expect { configure }.to raise_error(Coinbase::InvalidConfiguration, /API key private key/)
      end
    end

    context 'when api_key_name is nil' do
      let(:api_key_name) { nil }

      it 'raises an exception' do
        expect { configure }.to raise_error(Coinbase::InvalidConfiguration, /API key name/)
      end
    end
  end

  describe '.configure_from_json' do
    before do
      described_class.configure_from_json(file_path)
    end

    let(:file_path) { 'spec/fixtures/cdp_api_key.json' }

    it 'configures the API key name' do
      expect(described_class.configuration.api_key_name).not_to be_nil
    end

    it 'correctly configures the API key private key' do
      expect(described_class.configuration.api_key_private_key).not_to be_nil
    end
  end

  describe '.to_sym' do
    context 'when the value is a string' do
      it 'returns the symbolized version of the string' do
        expect(described_class.to_sym('base-mainnet')).to eq :base_mainnet
      end
    end

    context 'when the value is already a symbol' do
      it 'returns the same symbol' do
        expect(described_class.to_sym(:base_mainnet)).to eq :base_mainnet
      end
    end
  end

  describe '.normalize_network' do
    context 'when the value is a symbol' do
      it 'returns the normalized network string' do
        expect(described_class.normalize_network(:base_mainnet)).to eq 'base-mainnet'
      end
    end

    context 'when the value is already a string' do
      it 'returns the symbolized version of the string' do
        expect(described_class.normalize_network('base-mainnet')).to eq 'base-mainnet'
      end
    end
  end

  describe '.default_user' do
    let(:users_api) { instance_double(Coinbase::Client::UsersApi) }
    let(:user_model) { instance_double(Coinbase::Client::User) }

    before do
      allow(Coinbase::Client::UsersApi).to receive(:new).and_return(users_api)
      allow(users_api).to receive(:get_current_user).and_return(user_model)
      allow(Coinbase::User).to receive(:new)
    end

    it 'creates a new users api client' do
      described_class.default_user
      expect(Coinbase::Client::UsersApi).to have_received(:new).with(described_class.configuration.api_client)
    end

    it 'gets the current user from the api' do
      described_class.default_user
      expect(users_api).to have_received(:get_current_user)
    end

    it 'creates a new user object from the response' do
      described_class.default_user
      expect(Coinbase::User).to have_received(:new).with(user_model)
    end
  end

  describe '.call_api' do
    context 'when the API call is successful' do
      it 'does not raise an error' do
        expect do
          described_class.call_api { 'success' }
        end.not_to raise_error
      end
    end

    context 'when the API call raises a standard error' do
      it 'raises the standard error' do
        expect do
          described_class.call_api { raise StandardError, 'error' }
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
          described_class.call_api { raise err }
        end.to raise_error(Coinbase::UnimplementedError)
      end
    end
  end

  describe '.pretty_print_object' do
    context 'with no details' do
      subject(:stringified_object) { described_class.pretty_print_object(Coinbase::Balance) }

      it 'returns a string with the class name and no details' do
        expect(stringified_object).to eq 'Coinbase::Balance{}'
      end
    end

    context 'with details' do
      subject(:stringified_object) do
        described_class.pretty_print_object(
          Coinbase::Balance,
          amount: 100,
          asset_id: :eth,
          null_value: nil
        )
      end

      it 'returns a string with the class name and all non-nil details' do
        expect(stringified_object).to eq "Coinbase::Balance{amount: '100', asset_id: 'eth'}"
      end
    end
  end

  describe '.use_server_signer?' do
    let(:api_key_private_key) { 'some-key' }
    let(:api_key_name) { 'some-key-name' }

    before do
      described_class.configure do |config|
        config.api_key_private_key = api_key_private_key
        config.api_key_name = api_key_name
        config.use_server_signer = server_signer
      end
    end

    [true, false].each do |use_server_signer|
      context "when the configuration is set to #{use_server_signer}" do
        let(:server_signer) { use_server_signer }

        it 'returns the value of the configuration' do
          expect(described_class.use_server_signer?).to eq(use_server_signer)
        end
      end
    end
  end

  describe '.configured?' do
    let(:api_key_private_key) { 'some-key' }
    let(:api_key_name) { 'some-key-name' }

    context 'when the configuration is set' do
      before do
        described_class.configure do |config|
          config.api_key_name = api_key_name
          config.api_key_private_key = api_key_private_key
        end
      end

      it 'is configured' do
        expect(described_class).to be_configured
      end
    end

    context 'when the configuration is not set' do
      it 'is not configured' do
        expect(described_class).not_to be_configured
      end
    end

    context 'when the private key is not set' do
      before do
        described_class.configuration.api_key_name = api_key_name
      end

      it 'is not configured' do
        expect(described_class).not_to be_configured
      end
    end

    context 'when the api key name is not set' do
      before do
        described_class.configuration.api_key_private_key = api_key_private_key
      end

      it 'is not configured' do
        expect(described_class).not_to be_configured
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
