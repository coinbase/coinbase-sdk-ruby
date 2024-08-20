# frozen_string_literal: true

describe Coinbase::SmartContract do
  let(:network_id) { 'ethereum-mainnet' }
  let(:protocol_name) { 'uniswap' }
  let(:contract_address) { '0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48' }
  let(:contract_name) { 'Pool' }
  let(:event_name) { 'Transfer' }
  let(:from_block_height) { 201_782_330 }
  let(:to_block_height) { 201_782_340 }
  let(:contract_events_api) { instance_double(Coinbase::Client::ContractEventsApi) }
  let(:contract_event_model) { build(:contract_event_model) }
  let(:contract_event) { build(:contract_event, model: contract_event_model) }

  before do
    allow(Coinbase::Client::ContractEventsApi).to receive(:new).and_return(contract_events_api)
    allow(contract_events_api).to receive(:list_contract_events).and_return(
      instance_double(Coinbase::Client::ContractEventList, data: [contract_event_model],
                                                           has_more: true,
                                                           next_page: 'next_page'),
      instance_double(Coinbase::Client::ContractEventList, data: [], has_more: false)
    )
  end

  describe '.list_events' do
    subject(:list_events) do
      described_class.list_events(
        network_id: network_id,
        protocol_name: protocol_name,
        contract_address: contract_address,
        contract_name: contract_name,
        event_name: event_name,
        from_block_height: from_block_height,
        to_block_height: to_block_height
      )
    end

    it 'fetches the first page of contract events' do # rubocop:disable RSpec/ExampleLength
      list_events.to_a

      expect(contract_events_api).to have_received(:list_contract_events).with(
        network_id,
        protocol_name,
        contract_address,
        contract_name,
        event_name,
        from_block_height,
        to_block_height,
        { next_page: nil }
      )
    end

    it 'fetches the last page of contract events' do # rubocop:disable RSpec/ExampleLength
      list_events.to_a

      expect(contract_events_api).to have_received(:list_contract_events).with(
        network_id,
        protocol_name,
        contract_address,
        contract_name,
        event_name,
        from_block_height,
        to_block_height,
        { next_page: 'next_page' }
      )
    end

    it 'returns an enumerator' do
      expect(list_events).to be_an(Enumerator)
    end
  end
end
