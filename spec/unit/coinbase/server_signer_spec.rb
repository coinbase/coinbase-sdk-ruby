# frozen_string_literal: true

describe Coinbase::ServerSigner do
  subject(:server_signer) { described_class.new(model) }

  let(:server_signer_id) { SecureRandom.uuid }
  let(:wallet_ids) { [SecureRandom.uuid, SecureRandom.uuid, SecureRandom.uuid] }
  let(:model) do
    Coinbase::Client::ServerSigner.new(server_signer_id: server_signer_id, wallets: wallet_ids)
  end
  let(:server_signers_api) { instance_double(Coinbase::Client::ServerSignersApi) }

  before do
    allow(Coinbase::Client::ServerSignersApi).to receive(:new).and_return(server_signers_api)
  end

  describe '.default' do
    subject(:default_server_signer) { described_class.default }

    before do
      allow(server_signers_api).to receive(:list_server_signers).and_return(list_response)
    end

    context 'when a default Server-Signer exists' do
      let(:list_response) { Coinbase::Client::ServerSignerList.new(data: [model], total_count: 1) }

      it 'returns the default Server-Signer' do
        expect(default_server_signer.id).to eq(server_signer_id)
      end

      it 'sets the wallets on the Server-Signer' do
        expect(default_server_signer.wallets).to eq(wallet_ids)
      end
    end

    context 'when a default Server-Signer does not exist' do
      let(:list_response) do
        Coinbase::Client::ServerSignerList.new(data: [], total_count: 0)
      end

      it 'throws an error' do
        expect do
          described_class.default
        end.to raise_error('No Server-Signer is associated with the project')
      end
    end
  end

  describe '#initialize' do
    it 'initializes a new Server-Signer' do
      expect(server_signer).to be_a(described_class)
    end
  end

  describe '#id' do
    it 'returns the Server-Signer ID' do
      expect(server_signer.id).to eq(server_signer_id)
    end
  end

  describe '#wallets' do
    it 'returns the wallets' do
      expect(server_signer.wallets).to eq(wallet_ids)
    end
  end

  describe '#inspect' do
    it 'includes the Server-Signer ID' do
      expect(server_signer.inspect).to include(server_signer_id)
    end

    it 'includes wallets' do
      expect(server_signer.inspect).to include(wallet_ids.join(', '))
    end

    it 'returns the same value as #to_s' do
      expect(server_signer.inspect).to eq(server_signer.to_s)
    end
  end
end
