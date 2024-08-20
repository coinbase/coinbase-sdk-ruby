# frozen_string_literal: true

describe Coinbase::Validator do
  let(:normalized_network_id) { 'base-sepolia' }
  let(:network_id) { :base_sepolia }
  let(:network) { build(:network, network_id) }
  let(:asset_id) { :asset_id }
  let(:validator_id) { 'validator_id' }
  let(:stake_api) { instance_double(Coinbase::Client::ValidatorsApi) }
  let(:validator_model) do
    instance_double(
      Coinbase::Client::Validator,
      status: 'validator_status',
      details: Coinbase::Client::EthereumValidatorMetadata
    )
  end

  before do
    allow(Coinbase::Client::ValidatorsApi).to receive(:new).and_return(stake_api)
    allow(stake_api).to receive(:get_validator).and_return(validator_model)
  end

  describe '.fetch' do
    subject(:fetch) { described_class.fetch(network_id, asset_id, validator_id) }

    before do
      allow(Coinbase::Network).to receive(:from_id).with(network_id).and_return(network)
    end

    it 'fetches the validator' do
      fetch

      expect(stake_api).to have_received(:get_validator).with(
        normalized_network_id,
        asset_id,
        validator_id
      )
    end

    it 'returns a validator' do
      expect(fetch).to have_attributes(
        status: 'validator_status'
      )
    end
  end

  describe '.list' do
    subject(:list) { described_class.list(network_id, asset_id, status: status) }

    let(:status) { 'status' }
    let(:page) { 1 }

    before do
      allow(Coinbase::Network).to receive(:from_id).with(network_id).and_return(network)

      allow(stake_api).to receive(:list_validators).and_return(
        instance_double(Coinbase::Client::ValidatorList, data: [validator_model], has_more: false)
      )
    end

    it 'fetches the validators' do
      list.first

      expect(stake_api).to have_received(:list_validators).with(
        normalized_network_id,
        asset_id,
        {
          status: status,
          page: nil
        }
      )
    end

    it 'returns a list of validators' do
      expect(list).to all(be_a(described_class))
    end
  end
end
