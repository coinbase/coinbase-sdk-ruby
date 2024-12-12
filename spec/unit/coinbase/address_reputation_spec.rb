# frozen_string_literal: true

describe Coinbase::AddressReputation do
  let(:address_id) { '0x123456789abcdef' }
  let(:network) { 'ethereum-mainnet' }
  let(:mock_model) do
    instance_double(
      Coinbase::Client::AddressReputation,
      is_a?: true, # Mock `is_a?` to return true for the expected class
      score: 50,
      metadata: {
        total_transactions: 1,
        unique_days_active: 1,
        longest_active_streak: 1,
        current_active_streak: 2,
        activity_period_days: 3,
        bridge_transactions_performed: 4,
        lend_borrow_stake_transactions: 5,
        ens_contract_interactions: 6,
        smart_contract_deployments: 7,
        token_swaps_performed: 8
      }
    )
  end

  before do
    allow(Coinbase).to receive(:call_api).and_return(mock_model)
    allow(Coinbase::Client::ReputationApi).to receive(:new).and_return(instance_double(Coinbase::Client::ReputationApi))
  end

  describe '.fetch' do
    it 'fetches the address reputation from the API' do
      reputation = described_class.fetch(address_id: address_id, network: network)
      expect(reputation).to be_a(described_class)
    end

    it 'initializes the object with the correct score' do
      reputation = described_class.fetch(address_id: address_id, network: network)
      expect(reputation.score).to eq(50)
    end

    it 'raises an error if the API returns an invalid model' do
      allow(Coinbase).to receive(:call_api).and_return(nil)

      expect do
        described_class.fetch(address_id: address_id, network: network)
      end.to raise_error(ArgumentError, 'must be an AddressReputation client object')
    end
  end

  describe '#score' do
    it 'returns the reputation score' do
      reputation = described_class.new(mock_model)
      expect(reputation.score).to eq(50)
    end
  end

  describe '#metadata' do
    it 'returns metadata as a Metadata object' do
      reputation = described_class.new(mock_model)
      metadata = reputation.metadata

      expect(metadata).to be_a(Coinbase::AddressReputation::Metadata)
    end

    it 'has correct metadata values for total transactions' do
      reputation = described_class.new(mock_model)
      metadata = reputation.metadata

      expect(metadata.to_h[:total_transactions]).to eq(1)
    end
  end

  describe '#risky?' do
    it 'returns false for a positive score' do
      reputation = described_class.new(mock_model)
      expect(reputation.risky?).to be false
    end

    it 'returns true for a negative score' do
      allow(mock_model).to receive(:score).and_return(-10)
      reputation = described_class.new(mock_model)
      expect(reputation.risky?).to be true
    end
  end

  describe '#to_s' do
    it 'returns a string containing the score only' do
      reputation = described_class.new(mock_model)
      expected_output = /Coinbase::AddressReputation\{score: '50'/
      expect(reputation.to_s).to match(expected_output)
    end
  end
end
