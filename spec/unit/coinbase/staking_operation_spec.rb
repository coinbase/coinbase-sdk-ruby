# frozen_string_literal: true

describe Coinbase::StakingOperation do
  let(:network_id) { :ethereum_holesky }
  let(:address_id) { 'address_id' }
  let(:staking_operation_model) do
    instance_double(Coinbase::Client::StakingOperation, status: :initialized, id: 'some_id',
                                                        network_id: 'ethereum-holesky', address_id: 'address_id')
  end
  let(:staking_operation) { described_class.new(staking_operation_model) }
  let(:transaction_model) { instance_double(Coinbase::Client::Transaction) }
  let(:transaction) { instance_double(Coinbase::Transaction) }
  let(:key) { instance_double(Eth::Key) }

  let(:stake_api) { double('Coinbase::Client::StakeApi') }

  before(:each) do
    allow(Coinbase::Client::StakeApi).to receive(:new).and_return(stake_api)
  end

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

  describe '#wait!' do
    let(:updated_staking_operation_model) do
      Coinbase::Client::StakingOperation.new(
        status: 'complete',
        transactions: [transaction_model]
      )
    end

    before do
      allow(staking_operation).to receive(:sleep)

      allow(stake_api)
        .to receive(:get_external_staking_operation)
        .with(network_id, address_id, staking_operation.id)
        .and_return(staking_operation_model, staking_operation_model, updated_staking_operation_model)
    end

    context 'when the staking operation is completed' do
      it 'returns the completed StakingOperation' do
        expect(staking_operation.wait!).to eq(staking_operation)
        expect(staking_operation.status).to eq('complete')
      end
    end

    context 'when the staking operation times out' do
      let(:updated_staking_operation_model) do
        Coinbase::Client::StakingOperation.new(
          status: 'initialized',
          transactions: [transaction_model]
        )
      end

      it 'raises a Timeout::Error' do
        expect { staking_operation.wait!(0.2, 0.00001) }.to raise_error(Timeout::Error, 'Staking Operation timed out')
      end
    end
  end
end
