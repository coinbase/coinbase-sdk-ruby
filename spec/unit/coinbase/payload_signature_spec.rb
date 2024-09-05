# frozen_string_literal: true

describe Coinbase::PayloadSignature do
  subject(:payload_signature) { described_class.new(model) }

  let(:signing_key) { build(:key) }
  let(:address_id) { signing_key.address.to_s }
  let(:payload_signature_id) { SecureRandom.uuid }
  let(:wallet_id) { SecureRandom.uuid }
  let(:pending_model) do
    build(:payload_signature_model, :pending, key: signing_key, wallet_id: wallet_id,
                                              payload_signature_id: payload_signature_id)
  end
  let(:model) do
    build(:payload_signature_model, :signed, key: signing_key, wallet_id: wallet_id,
                                             payload_signature_id: payload_signature_id)
  end

  let(:unsigned_payload) { model.unsigned_payload }
  let(:addresses_api) { instance_double(Coinbase::Client::AddressesApi) }
  let(:signature) { model.signature }

  before do
    allow(Coinbase::Client::AddressesApi).to receive(:new).and_return(addresses_api)
  end

  describe '.create' do
    context 'when not using a server-signer' do
      subject(:payload_signature) do
        described_class.create(
          wallet_id: wallet_id,
          address_id: address_id,
          unsigned_payload: unsigned_payload,
          signature: signature
        )
      end

      let(:create_payload_signature_request) do
        {
          unsigned_payload: unsigned_payload,
          signature: signature
        }
      end

      before do
        allow(addresses_api)
          .to receive(:create_payload_signature)
          .with(wallet_id, address_id, create_payload_signature_request: create_payload_signature_request)
          .and_return(model)
      end

      it 'creates a new PayloadSignature' do
        expect(payload_signature).to be_a(described_class)
      end

      it 'sets the payload signature properties' do
        expect(payload_signature.signature).to eq(signature)
      end
    end

    context 'when signing with a server-signer' do
      subject(:payload_signature) do
        described_class.create(
          wallet_id: wallet_id,
          address_id: address_id,
          unsigned_payload: unsigned_payload
        )
      end

      let(:create_pending_payload_signature_request) do
        {
          unsigned_payload: unsigned_payload
        }
      end

      before do
        allow(addresses_api)
          .to receive(:create_payload_signature)
          .with(wallet_id, address_id, create_payload_signature_request: create_pending_payload_signature_request)
          .and_return(pending_model)
      end

      it 'creates a new PayloadSignature' do
        expect(payload_signature).to be_a(described_class)
      end

      it 'sets the payload signature properties' do
        expect(payload_signature.id).to eq(model.payload_signature_id)
      end
    end
  end

  describe '.list' do
    subject(:enumerator) do
      described_class.list(wallet_id: wallet_id, address_id: address_id)
    end

    let(:api) { addresses_api }
    let(:fetch_params) { ->(page) { [wallet_id, address_id, { limit: 100, page: page }] } }
    let(:resource_list_klass) { Coinbase::Client::PayloadSignatureList }
    let(:item_klass) { described_class }
    let(:item_initialize_args) { nil }
    let(:create_model) do
      lambda { |id|
        build(:payload_signature_model, :signed, wallet_id: wallet_id, payload_signature_id: id, key: signing_key)
      }
    end

    it_behaves_like 'it is a paginated enumerator', :payload_signatures
  end

  describe '#initialize' do
    it 'initializes a new PayloadSignature' do
      expect(payload_signature).to be_a(described_class)
    end

    context 'when initialized with a model of a different type' do
      it 'raises an error' do
        expect do
          described_class.new(build(:balance_model, :base_sepolia))
        end.to raise_error(RuntimeError)
      end
    end
  end

  describe '#id' do
    it 'returns the payload signature ID' do
      expect(payload_signature.id).to eq(model.payload_signature_id)
    end
  end

  describe '#wallet_id' do
    it 'returns the wallet ID' do
      expect(payload_signature.wallet_id).to eq(wallet_id)
    end
  end

  describe '#address_id' do
    it 'returns the signing address ID' do
      expect(payload_signature.address_id).to eq(address_id)
    end
  end

  describe '#reload' do
    before do
      allow(addresses_api)
        .to receive(:get_payload_signature)
        .with(payload_signature.wallet_id, payload_signature.address_id, payload_signature.id)
        .and_return(model)
    end

    it 'updates the payload signature' do
      expect(payload_signature.reload.status).to eq(Coinbase::PayloadSignature::Status::SIGNED)
    end

    it 'updates properties on the payload signature' do
      expect(payload_signature.reload.signature).to eq(signature)
    end
  end

  describe '#wait!' do
    let(:updated_model) { model }

    before do
      allow(payload_signature).to receive(:sleep) # rubocop:disable RSpec/SubjectStub

      allow(addresses_api)
        .to receive(:get_payload_signature)
        .with(payload_signature.wallet_id, payload_signature.address_id, payload_signature.id)
        .and_return(pending_model, pending_model, updated_model)
    end

    context 'when the payload signature is signed' do
      it 'returns the completed PayloadSignature' do
        expect(payload_signature.wait!.status).to eq(Coinbase::PayloadSignature::Status::SIGNED)
      end
    end

    context 'when the payload signature is failed' do
      let(:updated_model) do
        build(:payload_signature_model, :failed, wallet_id: wallet_id, payload_signature_id: payload_signature_id)
      end

      it 'returns the failed PayloadSignature' do
        expect(payload_signature.wait!.status).to eq(Coinbase::PayloadSignature::Status::FAILED)
      end
    end

    context 'when the payload signature times out' do
      let(:updated_model) { pending_model }

      it 'raises a Timeout::Error' do
        expect { payload_signature.wait!(0.2, 0.00001) }.to raise_error(Timeout::Error, 'Payload Signature timed out')
      end
    end
  end

  describe '#inspect' do
    it 'includes payload signature details' do
      expect(payload_signature.inspect).to include(
        wallet_id,
        address_id,
        model.payload_signature_id,
        model.unsigned_payload,
        model.signature,
        payload_signature.status.to_s
      )
    end

    it 'returns the same value as to_s' do
      expect(payload_signature.inspect).to eq(payload_signature.to_s)
    end
  end
end
