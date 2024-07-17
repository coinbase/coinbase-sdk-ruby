# frozen_string_literal: true

describe Coinbase::StakingOperation do
  let(:staking_operation_model) { instance_double(Coinbase::Client::StakingOperation, status: :initialized) }
  let(:staking_operation) { described_class.new(staking_operation_model) }
  let(:transaction_model) { instance_double(Coinbase::Client::Transaction) }
  let(:transaction) { instance_double(Coinbase::Transaction) }
  let(:key) { instance_double(Eth::Key) }

  before do
    allow(staking_operation_model).to receive(:transactions).and_return([transaction_model])
    allow(Coinbase::Transaction).to receive(:new).and_return(transaction)
    allow(transaction).to receive(:signed?).and_return(false)
    allow(transaction).to receive(:sign)
  end

  describe '#initialize' do
    it 'creates a transaction for each transaction model' do
      expect(Coinbase::Transaction).to receive(:new).with(transaction_model)

      staking_operation
    end
  end

  describe '#sign' do
    it 'signs each transaction' do
      staking_operation.sign(key)

      expect(transaction).to have_received(:sign).with(key)
    end

    it 'does not sign already signed transactions' do
      allow(transaction).to receive(:signed?).and_return(true)

      staking_operation.sign(key)

      expect(transaction).not_to have_received(:sign)
    end
  end
end
