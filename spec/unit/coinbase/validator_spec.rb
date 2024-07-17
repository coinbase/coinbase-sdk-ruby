# frozen_string_literal: true

describe Coinbase::Validator do
  let(:network_id) { :network_id }
  let(:asset_id) { :asset_id }
  let(:validator_id) { 'validator_id' }
  let(:stake_api) { instance_double(Coinbase::Client::StakeApi) }
  let(:validator_model) do
    instance_double(Coinbase::Client::Validator, id: validator_id, name: 'validator_name', status: 'validator_status')
  end

  before do
    allow(Coinbase::Client::StakeApi).to receive(:new).and_return(stake_api)
    allow(stake_api).to receive(:get_validator).and_return(validator_model)
  end

  describe '.fetch' do
    subject(:fetch) { described_class.fetch(network_id, asset_id, validator_id) }

    it 'fetches the validator' do
      fetch

      expect(stake_api).to have_received(:get_validator).with(
        network_id: network_id,
        asset_id: asset_id,
        validator_id: validator_id
      )
    end

    it 'returns a validator' do
      expect(fetch).to have_attributes(
        id: validator_id,
        name: 'validator_name',
        status: 'validator_status'
      )
    end
  end
end
