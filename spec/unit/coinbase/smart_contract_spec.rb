# frozen_string_literal: true

describe Coinbase::SmartContract do
  subject(:smart_contract) do
    described_class.new(model)
  end

  let(:network_id) { :base_sepolia }
  let(:network) { build(:network, network_id) }
  let(:smart_contracts_api) { instance_double(Coinbase::Client::SmartContractsApi) }

  let(:token_name) { 'Test token' }
  let(:token_symbol) { 'TST' }
  let(:total_supply) { 1_000_000 }

  let(:model) do
    build(
      :smart_contract_model,
      network_id,
      name: token_name,
      symbol: token_symbol,
      total_supply: total_supply
    )
  end
  let(:wallet_id) { model.wallet_id }
  let(:address_id) { model.deployer_address }

  before do
    allow(Coinbase::Client::SmartContractsApi).to receive(:new).and_return(smart_contracts_api)

    allow(Coinbase::Network)
      .to receive(:from_id)
      .with(satisfy { |n| n == network || n == network_id || n == network.normalized_id })
      .and_return(network)
  end

  describe '.create_token_contract' do
    subject(:smart_contract) do
      described_class.create_token_contract(
        address_id: address_id,
        wallet_id: wallet_id,
        name: token_name,
        symbol: token_symbol,
        total_supply: total_supply
      )
    end

    let(:create_smart_contract_request) do
      {
        type: Coinbase::Client::SmartContractType::ERC20,
        options: Coinbase::Client::TokenContractOptions.new(
          name: token_name,
          symbol: token_symbol,
          total_supply: total_supply.to_s
        ).to_body
      }
    end

    before do
      allow(smart_contracts_api)
        .to receive(:create_smart_contract)
        .with(wallet_id, address_id, create_smart_contract_request)
        .and_return(model)
    end

    it 'creates a new SmartContract' do
      expect(smart_contract).to be_a(described_class)
    end

    it 'sets the smart_contract properties' do
      expect(smart_contract.id).to eq(model.smart_contract_id)
    end
  end

  describe '.list_events' do
    subject(:enumerator) do
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

    let(:network_id) { :ethereum_mainnet }
    let(:protocol_name) { 'uniswap' }
    let(:contract_address) { '0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48' }
    let(:contract_name) { 'Pool' }
    let(:event_name) { 'Transfer' }
    let(:from_block_height) { 201_782_330 }
    let(:to_block_height) { 201_782_340 }
    let(:contract_events_api) { instance_double(Coinbase::Client::ContractEventsApi) }
    let(:api) { contract_events_api }
    let(:fetch_params) do
      lambda do |page|
        [
          'ethereum-mainnet',
          protocol_name,
          contract_address,
          contract_name,
          event_name,
          from_block_height,
          to_block_height,
          { next_page: page }
        ]
      end
    end
    let(:resource_list_klass) { Coinbase::Client::ContractEventList }
    let(:item_klass) { Coinbase::ContractEvent }
    let(:item_initialize_args) { nil }
    let(:create_model) { ->(idx) { build(:contract_event_model, event_index: idx) } }

    before do
      allow(Coinbase::Client::ContractEventsApi).to receive(:new).and_return(contract_events_api)
    end

    it_behaves_like 'it is a paginated enumerator', :contract_events
  end

  describe '#initialize' do
    it 'creates a new SmartContract' do
      expect(smart_contract).to be_a(described_class)
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
    it 'returns the smart contract ID' do
      expect(smart_contract.id).to eq(model.smart_contract_id)
    end
  end

  describe '#network' do
    it 'returns the network' do
      expect(smart_contract.network).to eq(network)
    end
  end

  describe '#contract_address' do
    it 'returns the contract address' do
      expect(smart_contract.contract_address).to eq(model.contract_address)
    end
  end

  describe '#abi' do
    it 'returns the parsed contract ABI' do
      expect(smart_contract.abi).to eq(JSON.parse(model.abi))
    end
  end

  describe '#wallet_id' do
    it 'returns the wallet ID' do
      expect(smart_contract.wallet_id).to eq(wallet_id)
    end
  end

  describe '#deployer_address' do
    it 'returns the deployer address' do
      expect(smart_contract.deployer_address).to eq(model.deployer_address)
    end
  end

  describe '#type' do
    it 'returns the smart contract type' do
      expect(smart_contract.type).to eq(model.type)
    end
  end

  describe '#options' do
    it 'returns the smart contract options' do
      expect(smart_contract.options).to eq(model.options)
    end
  end

  describe '#transaction' do
    it 'returns the Transaction' do
      expect(smart_contract.transaction).to be_a(Coinbase::Transaction)
    end

    it 'sets the from_address_id' do
      expect(smart_contract.transaction.from_address_id).to eq(address_id)
    end
  end

  describe '#sign' do
    context 'when the key is valid' do
      subject(:signature) { smart_contract.sign(key) }

      let(:smart_contract) { build(:smart_contract, :pending, key: key) }
      let(:key) { Eth::Key.new }

      before { signature }

      it 'returns a string' do
        expect(signature).to be_a(String)
      end

      context 'when it is signed again' do
        it 'raises an error' do
          expect { smart_contract.sign(key) }.to raise_error(Coinbase::AlreadySignedError)
        end
      end
    end

    context 'when the key is not an Eth::Key' do
      let(:smart_contract) { build(:smart_contract, :pending) }

      it 'raises an error' do
        expect { smart_contract.sign('invalid key') }.to raise_error(RuntimeError)
      end
    end
  end

  describe '#deploy!' do
    subject(:deployed_smart_contract) { smart_contract.deploy! }

    let(:key) { Eth::Key.new }
    let(:smart_contract) { build(:smart_contract, :pending, key: key) }
    let(:address_id) { smart_contract.deployer_address }
    let(:wallet_id) { smart_contract.wallet_id }
    let(:smart_contract_id) { smart_contract.id }

    let(:broadcasted_transaction_model) { build(:transaction_model, :broadcasted, key: key) }
    let(:deployed_smart_contract_model) do
      instance_double(
        Coinbase::Client::SmartContract,
        transaction: broadcasted_transaction_model,
        deployer_address: address_id
      )
    end

    context 'when the transaction is signed' do
      let(:deploy_smart_contract_request) do
        { signed_payload: smart_contract.transaction.raw.hex }
      end

      before do
        smart_contract.transaction.sign(key)

        allow(smart_contracts_api)
          .to receive(:deploy_smart_contract)
          .with(wallet_id, address_id, smart_contract_id, deploy_smart_contract_request)
          .and_return(deployed_smart_contract_model)

        deployed_smart_contract
      end

      it 'returns the updated SmartContract' do
        expect(deployed_smart_contract).to be_a(described_class)
      end

      it 'broadcasts the transaction' do
        expect(smart_contracts_api)
          .to have_received(:deploy_smart_contract)
          .with(wallet_id, address_id, smart_contract_id, deploy_smart_contract_request)
      end

      it 'updates the transaction status' do
        expect(deployed_smart_contract.transaction.status).to eq(Coinbase::Transaction::Status::BROADCAST)
      end

      it 'sets the transaction signed payload' do
        expect(deployed_smart_contract.transaction.signed_payload)
          .to eq(broadcasted_transaction_model.signed_payload)
      end
    end

    context 'when the transaction is not signed' do
      it 'raises an error' do
        expect { deployed_smart_contract }.to raise_error(Coinbase::TransactionNotSignedError)
      end
    end
  end

  describe '#reload' do
    let(:updated_model) { build(:smart_contract_model, network_id, :completed) }

    before do
      allow(smart_contracts_api)
        .to receive(:get_smart_contract)
        .with(smart_contract.wallet_id, smart_contract.deployer_address, smart_contract.id)
        .and_return(updated_model)
    end

    it 'updates the smart contract transaction' do
      expect(smart_contract.reload.transaction.status).to eq(Coinbase::Transaction::Status::COMPLETE)
    end
  end

  describe '#wait!' do
    before do
      allow(smart_contract).to receive(:sleep) # rubocop:disable RSpec/SubjectStub

      allow(smart_contracts_api)
        .to receive(:get_smart_contract)
        .with(smart_contract.wallet_id, smart_contract.deployer_address, smart_contract.id)
        .and_return(updated_model)
    end

    context 'when the smart contract deployment has completed' do
      let(:updated_model) { build(:smart_contract_model, network_id, :completed) }

      it 'returns the completed Smart Contract' do
        expect(smart_contract.wait!.transaction.status).to eq(Coinbase::Transaction::Status::COMPLETE)
      end
    end

    context 'when the smart contract deployment has failed' do
      let(:updated_model) { build(:smart_contract_model, network_id, :failed) }

      it 'returns the failed Smart Contract' do
        expect(smart_contract.wait!.transaction.status).to eq(Coinbase::Transaction::Status::FAILED)
      end
    end

    context 'when the smart contract deployment times out' do
      let(:updated_model) { build(:smart_contract_model, network_id, :pending) }

      it 'raises a Timeout::Error' do
        expect do
          smart_contract.wait!(0.2, 0.00001)
        end.to raise_error(Timeout::Error, 'SmartContract deployment timed out. Try waiting again.')
      end
    end
  end

  describe '#inspect' do
    it 'includes smart contractdetails' do
      expect(smart_contract.inspect).to include(
        address_id,
        Coinbase.to_sym(network_id).to_s,
        smart_contract.transaction.status.to_s,
        token_name,
        token_symbol,
        total_supply.to_s
      )
    end

    it 'returns the same value as to_s' do
      expect(smart_contract.inspect).to eq(smart_contract.to_s)
    end

    context 'when the smart contract has been broadcast on chain' do
      let(:smart_contract_model) { build(:smart_contract_model, network_id, :broadcasted) }
      let(:smart_contract) { described_class.new(smart_contract_model) }

      it 'includes the updated status' do
        expect(smart_contract.inspect).to include('broadcast')
      end
    end
  end
end
