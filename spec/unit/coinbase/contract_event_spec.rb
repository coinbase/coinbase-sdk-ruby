# frozen_string_literal: true

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
