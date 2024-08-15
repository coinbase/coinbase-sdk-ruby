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

  describe Coinbase::ContractEvent do
    let(:contract_event_model) { build(:contract_event_model) }
    let(:contract_event) { described_class.new(contract_event_model) }

    describe '#network_id' do
      subject(:network_id) { contract_event.network_id }

      it { is_expected.to eq(contract_event_model.network_id) }
    end

    describe '#protocol_name' do
      subject(:protocol_name) { contract_event.protocol_name }

      it { is_expected.to eq(contract_event_model.protocol_name) }
    end

    describe '#contract_name' do
      subject(:contract_name) { contract_event.contract_name }

      it { is_expected.to eq(contract_event_model.contract_name) }
    end

    describe '#event_name' do
      subject(:event_name) { contract_event.event_name }

      it { is_expected.to eq(contract_event_model.event_name) }
    end

    describe '#sig' do
      subject(:sig) { contract_event.sig }

      it { is_expected.to eq(contract_event_model.sig) }
    end

    describe '#four_bytes' do
      subject(:four_bytes) { contract_event.four_bytes }

      it { is_expected.to eq(contract_event_model.four_bytes) }
    end

    describe '#contract_address' do
      subject(:contract_address) { contract_event.contract_address }

      it { is_expected.to eq(contract_event_model.contract_address) }
    end

    describe '#block_time' do
      subject(:block_time) { contract_event.block_time }

      it { is_expected.to eq(Time.parse(contract_event_model.block_time)) }
    end

    describe '#block_height' do
      subject(:block_height) { contract_event.block_height }

      it { is_expected.to eq(contract_event_model.block_height) }
    end

    describe '#tx_hash' do
      subject(:tx_hash) { contract_event.tx_hash }

      it { is_expected.to eq(contract_event_model.tx_hash) }
    end

    describe '#tx_index' do
      subject(:tx_index) { contract_event.tx_index }

      it { is_expected.to eq(contract_event_model.tx_index) }
    end

    describe '#event_index' do
      subject(:event_index) { contract_event.event_index }

      it { is_expected.to eq(contract_event_model.event_index) }
    end

    describe '#data' do
      subject(:data) { contract_event.data }

      it { is_expected.to eq(contract_event_model.data) }
    end

    describe '#to_s' do
      it 'returns a string representation of the ContractEvent' do
        expected_string = "Coinbase::ContractEvent{network_id: '#{contract_event_model.network_id}', " \
                          "protocol_name: '#{contract_event_model.protocol_name}', " \
                          "contract_name: '#{contract_event_model.contract_name}', " \
                          "event_name: '#{contract_event_model.event_name}', " \
                          "contract_address: '#{contract_event_model.contract_address}', " \
                          "block_height: #{contract_event_model.block_height}, " \
                          "tx_hash: '#{contract_event_model.tx_hash}', " \
                          "data: '#{contract_event_model.data}'}"
        expect(contract_event.to_s).to eq(expected_string)
      end
    end
  end
end
