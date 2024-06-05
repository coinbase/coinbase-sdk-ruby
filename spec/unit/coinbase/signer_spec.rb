# frozen_string_literal: true

describe Coinbase::Signer do
  let(:server_signer_id) { SecureRandom.uuid }
  let(:wallets) { [SecureRandom.uuid, SecureRandom.uuid, SecureRandom.uuid] }
  let(:model) { Coinbase::Client::ServerSigner.new('server_signer_id' => server_signer_id, 'wallets' => wallets) }
  let(:server_signer_list_model) do
    Coinbase::Client::ServerSignerList.new(
      'data' => [model],
      'total_count' => 1
    )
  end
  let(:empty_server_signer_list_model) do
    Coinbase::Client::ServerSignerList.new(
      'data' => [],
      'total_count' => 0
    )
  end
  let(:signers_api) { double('Coinbase::Client::ServerSignersApi') }

  subject(:signer) { described_class.new(model) }

  before do
    allow(Coinbase::Client::ServerSignersApi).to receive(:new).and_return(signers_api)
  end

  describe '#initialize' do
    it 'initializes a new Signer' do
      expect(signer).to be_a(Coinbase::Signer)
    end
  end

  describe '#id' do
    it 'returns the signer ID' do
      expect(signer.id).to eq(server_signer_id)
    end
  end

  describe '#wallets' do
    it 'returns the wallets' do
      expect(signer.wallets).to eq(wallets)
    end
  end

  describe '.default' do
    before do
      allow(signers_api).to receive(:list_server_signers).and_return(server_signer_list_model)
    end

    context 'when a default signer exists' do
      it 'returns the default signer' do
        default_signer = Coinbase::Signer.default
        expect(default_signer.id).to eq(server_signer_id)
        expect(default_signer.wallets).to eq(wallets)
      end
    end

    context 'when a default signer does not exist' do
      before do
        allow(signers_api).to receive(:list_server_signers).and_return(empty_server_signer_list_model)
      end

      it 'throws an error' do
        expect { Coinbase::Signer.default }.to raise_error("No Signer's associated with the project")
      end
    end
  end

  describe '#inspect' do
    it 'includes the signer ID' do
      expect(signer.inspect).to include(server_signer_id)
    end

    it 'includes wallets' do
      expect(signer.inspect).to include(wallets.join(', '))
    end

    it 'returns the same value as #to_s' do
      expect(signer.inspect).to eq(signer.to_s)
    end
  end
end
