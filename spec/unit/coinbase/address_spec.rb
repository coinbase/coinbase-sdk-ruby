# frozen_string_literal: true

describe Coinbase::Address do
  let(:network_id) { :ethereum_mainnet }
  let(:id) { '0x1234' }
  let(:model) { described_class.new(network_id, id) }

  describe '#id' do
    subject { model.id }

    it { is_expected.to eq(id) }
  end

  describe '#network_id' do
    subject { model.network_id }

    it { is_expected.to eq(network_id) }
  end

  describe '#inspect' do
    it 'matches to_s' do
      expect(model.inspect).to eq(model.to_s)
    end
  end

  describe '#can_sign?' do
    subject { model.can_sign? }

    it { is_expected.to be(false) }
  end

  describe '#balances' do
    it 'raises an error' do
      expect { model.balances }.to raise_error(NotImplementedError, 'Must be implemented by subclass')
    end
  end

  describe '#balance' do
    it 'raises an error' do
      expect { model.balance(:eth) }.to raise_error(NotImplementedError, 'Must be implemented by subclass')
    end
  end

  describe '#faucet' do
    it 'raises an error' do
      expect { model.faucet }.to raise_error(NotImplementedError, 'Must be implemented by subclass')
    end
  end
end
