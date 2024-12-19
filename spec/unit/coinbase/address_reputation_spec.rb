# frozen_string_literal: true

describe Coinbase::AddressReputation do
  subject(:address_reputation) { described_class.new(model) }

  let(:address_id) { '0x123456789abcdef' }
  let(:network) { 'ethereum-mainnet' }
  let(:score) { 50 }
  let(:model) { build(:address_reputation_model, score: score) }

  describe '.fetch' do
    subject(:address_reputation) { described_class.fetch(address_id: address_id, network: network) }

    let(:api_instance) { instance_double(Coinbase::Client::ReputationApi) }

    before do
      allow(Coinbase::Client::ReputationApi).to receive(:new).and_return(api_instance)
      allow(api_instance).to receive(:get_address_reputation).and_return(model)

      address_reputation
    end

    it 'fetches address reputation for the given network and address' do
      expect(api_instance).to have_received(:get_address_reputation).with(network, address_id)
    end

    it 'returns an AddressReputation object' do
      expect(address_reputation).to be_a(described_class)
    end

    it 'returns an object initialized with the correct model' do
      expect(address_reputation.instance_variable_get(:@model)).to eq(model)
    end

    it 'raises an error if the API returns an invalid model' do
      allow(api_instance).to receive(:get_address_reputation).and_return(nil)

      expect do
        described_class.fetch(address_id: address_id, network: network)
      end.to raise_error(ArgumentError, 'must be an AddressReputation object')
    end
  end

  describe '#score' do
    it 'returns the reputation score' do
      expect(address_reputation.score).to eq(score)
    end
  end

  describe '#metadata' do
    it 'returns a Metadata object' do
      expect(address_reputation.metadata).to be_a(described_class::Metadata)
    end

    it 'initalizes the metadata object properly' do
      model.metadata.all? do |key, value|
        expect(address_reputation.metadata.send(key)).to eq(value)
      end
    end
  end

  describe '#risky?' do
    context 'when the score is positive' do
      let(:score) { 42 }

      it 'returns false' do
        expect(address_reputation).not_to be_risky
      end
    end

    context 'when the score is negative' do
      let(:score) { -10 }

      it 'returns true' do
        expect(address_reputation).to be_risky
      end
    end
  end

  describe '#to_s' do
    it 'includes the score and the metadata details' do
      expect(address_reputation.inspect).to include(
        score.to_s,
        *address_reputation.metadata.to_h.values.map(&:to_s)
      )
    end
  end

  describe '#inspect' do
    it 'matches the output of #to_s' do
      expect(address_reputation.inspect).to eq(address_reputation.to_s)
    end
  end
end
