# frozen_string_literal: true

describe Coinbase::ContractInvocation do
  subject(:contract_invocation) do
    described_class.new(model)
  end

  let(:from_key) { Eth::Key.new }
  let(:network_id) { :base_sepolia }
  let(:network) { build(:network, network_id) }
  let(:wallet_id) { SecureRandom.uuid }
  let(:address_id) { from_key.address.to_s }
  let(:contract_invocation_id) { SecureRandom.uuid }
  let(:transaction_model) { build(:transaction_model, key: from_key) }
  let(:abi) do
    [
      {
        inputs: [{ internalType: 'address', name: 'recipient', type: 'address' }],
        name: 'mint',
        outputs: [{ internalType: 'uint256', name: '', type: 'uint256' }],
        stateMutability: 'payable',
        type: 'function'
      }
    ]
  end
  let(:method) { 'mint' }
  let(:contract_address) { '0xa82aB8504fDeb2dADAa3B4F075E967BbE35065b9' }
  let(:args) do
    { recipient: '0x475d41de7A81298Ba263184996800CBcaAD73C0b' }
  end
  let(:model) do
    Coinbase::Client::ContractInvocation.new(
      network_id: network_id,
      wallet_id: wallet_id,
      address_id: address_id,
      contract_invocation_id: contract_invocation_id,
      contract_address: contract_address,
      abi: abi.to_json,
      method: method,
      args: args.to_json,
      transaction: transaction_model
    )
  end
  let(:contract_invocations_api) { instance_double(Coinbase::Client::ContractInvocationsApi) }

  before do
    allow(Coinbase::Client::ContractInvocationsApi)
      .to receive(:new).and_return(contract_invocations_api)

    allow(Coinbase::Network)
      .to receive(:from_id)
      .with(satisfy { |n| n == network || n == network_id || n == network.normalized_id })
      .and_return(network)
  end

  describe '.create' do
    subject(:contract_invocation) do
      described_class.create(
        address_id: address_id,
        wallet_id: wallet_id,
        contract_address: contract_address,
        abi: abi,
        method: method,
        args: args
      )
    end

    let(:create_contract_invocation_request) do
      {
        contract_address: contract_address,
        abi: abi.to_json,
        method: method,
        args: args.to_json
      }
    end

    before do
      allow(contract_invocations_api)
        .to receive(:create_contract_invocation)
        .with(wallet_id, address_id, create_contract_invocation_request)
        .and_return(model)
    end

    it 'creates a new ContractInvocation' do
      expect(contract_invocation).to be_a(described_class)
    end

    it 'sets the contract_invocation properties' do
      expect(contract_invocation.id).to eq(contract_invocation_id)
    end
  end

  describe '.list' do
    subject(:enumerator) do
      described_class.list(wallet_id: wallet_id, address_id: address_id)
    end

    let(:api) { contract_invocations_api }
    let(:fetch_params) { ->(page) { [wallet_id, address_id, { limit: 100, page: page }] } }
    let(:resource_list_klass) { Coinbase::Client::ContractInvocationList }
    let(:item_klass) { described_class }
    let(:item_initialize_args) { nil }
    let(:create_model) do
      ->(id) { Coinbase::Client::ContractInvocation.new(contract_invocation_id: id, network_id: network.normalized_id) }
    end

    it_behaves_like 'it is a paginated enumerator', :contract_invocations
  end

  describe '#initialize' do
    it 'initializes a new ContractInvocation' do
      expect(contract_invocation).to be_a(described_class)
    end

    context 'when initialized with a model of a different type' do
      it 'raises an error' do
        expect do
          described_class.new(build(:balance_model, network_id))
        end.to raise_error(StandardError)
      end
    end
  end

  describe '#id' do
    it 'returns the contract_invocation ID' do
      expect(contract_invocation.id).to eq(contract_invocation_id)
    end
  end

  describe '#network' do
    it 'returns the network' do
      expect(contract_invocation.network).to eq(network)
    end
  end

  describe '#wallet_id' do
    it 'returns the wallet ID' do
      expect(contract_invocation.wallet_id).to eq(wallet_id)
    end
  end

  describe '#address_id' do
    it 'returns the address ID' do
      expect(contract_invocation.address_id).to eq(address_id)
    end
  end

  describe '#method' do
    it 'returns the contract method' do
      expect(contract_invocation.method).to eq(model.method)
    end
  end

  describe '#args' do
    it 'returns the parsed contract arguments' do
      expect(contract_invocation.args).to eq(args)
    end
  end

  describe '#abi' do
    it 'returns the parsed contract ABI' do
      expect(contract_invocation.abi).to eq(JSON.parse(abi.to_json))
    end
  end

  describe '#contract_address' do
    it 'returns the contract address' do
      expect(contract_invocation.contract_address).to eq(contract_address)
    end
  end

  describe '#transaction' do
    it 'returns the Transaction' do
      expect(contract_invocation.transaction).to be_a(Coinbase::Transaction)
    end

    it 'sets the from_address_id' do
      expect(contract_invocation.transaction.from_address_id).to eq(address_id)
    end
  end

  describe '#status' do
    it 'returns the transaction status' do
      expect(contract_invocation.status).to eq(Coinbase::Transaction::Status::PENDING)
    end
  end

  describe '#broadcast!' do
    subject(:broadcasted_contract_invocation) { contract_invocation.broadcast! }

    let(:broadcasted_transaction_model) { build(:transaction_model, :broadcasted, key: from_key) }
    let(:broadcasted_contract_invocation_model) do
      instance_double(
        Coinbase::Client::ContractInvocation,
        transaction: broadcasted_transaction_model,
        address_id: address_id
      )
    end

    context 'when the transaction is signed' do
      let(:broadcast_contract_invocation_request) do
        { signed_payload: contract_invocation.transaction.raw.hex }
      end

      before do
        contract_invocation.transaction.sign(from_key)

        allow(contract_invocations_api)
          .to receive(:broadcast_contract_invocation)
          .with(wallet_id, address_id, contract_invocation_id, broadcast_contract_invocation_request)
          .and_return(broadcasted_contract_invocation_model)

        broadcasted_contract_invocation
      end

      it 'returns the updated ContractInvocation' do
        expect(broadcasted_contract_invocation).to be_a(described_class)
      end

      it 'broadcasts the transaction' do
        expect(contract_invocations_api)
          .to have_received(:broadcast_contract_invocation)
          .with(wallet_id, address_id, contract_invocation_id, broadcast_contract_invocation_request)
      end

      it 'updates the transaction status' do
        expect(broadcasted_contract_invocation.transaction.status).to eq(Coinbase::Transaction::Status::BROADCAST)
      end

      it 'sets the transaction signed payload' do
        expect(broadcasted_contract_invocation.transaction.signed_payload)
          .to eq(broadcasted_transaction_model.signed_payload)
      end
    end

    context 'when the transaction is not signed' do
      it 'raises an error' do
        expect { broadcasted_contract_invocation }.to raise_error(Coinbase::TransactionNotSignedError)
      end
    end
  end

  describe '#reload' do
    let(:updated_transaction_model) { build(:transaction_model, :completed, key: from_key) }

    let(:updated_model) do
      Coinbase::Client::ContractInvocation.new(
        network_id: network_id,
        wallet_id: wallet_id,
        address_id: address_id,
        contract_invocation_id: contract_invocation_id,
        contract_address: contract_address,
        abi: abi.to_json,
        method: method,
        args: args.to_json,
        transaction: updated_transaction_model
      )
    end

    before do
      allow(contract_invocations_api)
        .to receive(:get_contract_invocation)
        .with(contract_invocation.wallet_id, contract_invocation.address_id, contract_invocation.id)
        .and_return(updated_model)
    end

    it 'updates the contract_invocation transaction' do
      expect(contract_invocation.reload.transaction.status).to eq(Coinbase::Transaction::Status::COMPLETE)
    end
  end

  describe '#wait!' do
    let(:updated_model) do
      Coinbase::Client::ContractInvocation.new(
        network_id: network_id,
        wallet_id: wallet_id,
        address_id: address_id,
        contract_invocation_id: contract_invocation_id,
        contract_address: contract_address,
        abi: abi.to_json,
        method: method,
        args: args.to_json,
        transaction: updated_transaction_model
      )
    end

    before do
      allow(contract_invocation).to receive(:sleep) # rubocop:disable RSpec/SubjectStub

      allow(contract_invocations_api)
        .to receive(:get_contract_invocation)
        .with(contract_invocation.wallet_id, contract_invocation.address_id, contract_invocation.id)
        .and_return(model, model, updated_model)
    end

    context 'when the contract_invocation is completed' do
      let(:updated_transaction_model) { build(:transaction_model, :completed, key: from_key) }

      it 'returns the completed ContractInvocation' do
        expect(contract_invocation.wait!.status).to eq(Coinbase::Transaction::Status::COMPLETE)
      end
    end

    context 'when the contract_invocation is failed' do
      let(:updated_transaction_model) { build(:transaction_model, :failed, key: from_key) }

      it 'returns the failed ContractInvocation' do
        expect(contract_invocation.wait!.status).to eq(Coinbase::Transaction::Status::FAILED)
      end
    end

    context 'when the contract_invocation times out' do
      let(:updated_transaction_model) { build(:transaction_model, key: from_key) }

      it 'raises a Timeout::Error' do
        expect do
          contract_invocation.wait!(0.2, 0.00001)
        end.to raise_error(Timeout::Error, 'Contract Invocation timed out')
      end
    end
  end

  describe '#inspect' do
    let(:expected_amount) { to_asset.from_atomic_amount(to_amount) }

    it 'includes contract_invocation details' do
      expect(contract_invocation.inspect).to include(
        address_id,
        wallet_id,
        contract_invocation_id,
        Coinbase.to_sym(network_id).to_s,
        abi.to_json,
        method,
        args.to_json,
        contract_invocation.transaction.status.to_s
      )
    end

    it 'returns the same value as to_s' do
      expect(contract_invocation.inspect).to eq(contract_invocation.to_s)
    end

    context 'when the contract_invocation has been broadcast on chain' do
      let(:transaction_model) { build(:transaction_model, :broadcasted, key: from_key) }

      it 'includes the updated status' do
        expect(contract_invocation.inspect).to include('broadcast')
      end
    end
  end
end
