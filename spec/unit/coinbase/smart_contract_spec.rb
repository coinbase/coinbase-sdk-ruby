# frozen_string_literal: true

describe Coinbase::SmartContract do
  subject(:smart_contract) do
    described_class.new(model)
  end

  let(:network_id) { :base_sepolia }
  let(:network) { build(:network, network_id) }
  let(:default_network) { build(:network, :base_mainnet) }
  let(:token_name) { 'Test token' }
  let(:token_symbol) { 'TST' }
  let(:total_supply) { 1_000_000 }
  let(:wallet_id) { model.wallet_id }
  let(:address_id) { model.deployer_address }
  let(:smart_contracts_api) { instance_double(Coinbase::Client::SmartContractsApi) }
  let(:model) do
    build(
      :smart_contract_model,
      network_id,
      name: token_name,
      symbol: token_symbol,
      total_supply: total_supply
    )
  end

  before do
    allow(Coinbase::Client::SmartContractsApi).to receive(:new).and_return(smart_contracts_api)

    allow(Coinbase).to receive(:default_network).and_return(default_network)
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

  describe '.create_nft_contract' do
    subject(:smart_contract) do
      described_class.create_nft_contract(
        address_id: address_id,
        wallet_id: wallet_id,
        name: nft_name,
        symbol: nft_symbol,
        base_uri: base_uri
      )
    end

    let(:nft_name) { 'Test NFT' }
    let(:nft_symbol) { 'TNFT' }
    let(:base_uri) { 'https://example.com/nft/' }

    let(:create_smart_contract_request) do
      {
        type: Coinbase::Client::SmartContractType::ERC721,
        options: Coinbase::Client::NFTContractOptions.new(
          name: nft_name,
          symbol: nft_symbol,
          base_uri: base_uri
        ).to_body
      }
    end

    let(:nft_contract_model) do
      build(:smart_contract_model, network_id,
            type: Coinbase::Client::SmartContractType::ERC721,
            options: Coinbase::Client::NFTContractOptions.new(
              name: nft_name,
              symbol: nft_symbol,
              base_uri: base_uri
            ))
    end

    before do
      allow(Coinbase::Client::SmartContractsApi).to receive(:new).and_return(smart_contracts_api)
      allow(smart_contracts_api)
        .to receive(:create_smart_contract)
        .with(wallet_id, address_id, create_smart_contract_request)
        .and_return(nft_contract_model)
    end

    it 'creates a new SmartContract' do
      expect(smart_contract).to be_a(described_class)
    end

    it 'sets the smart_contract properties' do
      expect(smart_contract.id).to eq(nft_contract_model.smart_contract_id)
    end

    it 'sets the correct contract type' do
      expect(smart_contract.type).to eq(Coinbase::Client::SmartContractType::ERC721)
    end

    context 'when checking NFT options' do
      it 'sets the correct name' do
        expect(smart_contract.options.name).to eq(nft_name)
      end

      it 'sets the correct symbol' do
        expect(smart_contract.options.symbol).to eq(nft_symbol)
      end

      it 'sets the correct base URI' do
        expect(smart_contract.options.base_uri).to eq(base_uri)
      end
    end
  end

  describe '.create_multi_token_contract' do
    subject(:smart_contract) do
      described_class.create_multi_token_contract(
        address_id: address_id,
        wallet_id: wallet_id,
        uri: uri
      )
    end

    let(:uri) { 'https://example.com/token/{id}.json' }

    let(:create_smart_contract_request) do
      {
        type: Coinbase::Client::SmartContractType::ERC1155,
        options: Coinbase::Client::MultiTokenContractOptions.new(
          uri: uri
        ).to_body
      }
    end

    let(:multi_token_contract_model) do
      build(:smart_contract_model, network_id,
            type: Coinbase::Client::SmartContractType::ERC1155,
            options: Coinbase::Client::MultiTokenContractOptions.new(
              uri: uri
            ))
    end

    before do
      allow(Coinbase::Client::SmartContractsApi).to receive(:new).and_return(smart_contracts_api)
      allow(smart_contracts_api)
        .to receive(:create_smart_contract)
        .with(wallet_id, address_id, create_smart_contract_request)
        .and_return(multi_token_contract_model)
    end

    it 'creates a new SmartContract' do
      expect(smart_contract).to be_a(described_class)
    end

    it 'sets the smart_contract properties' do
      expect(smart_contract.id).to eq(multi_token_contract_model.smart_contract_id)
    end

    it 'sets the correct contract type' do
      expect(smart_contract.type).to eq(Coinbase::Client::SmartContractType::ERC1155)
    end

    context 'when checking Multi-Token options' do
      it 'sets the correct URI' do
        expect(smart_contract.options.uri).to eq(uri)
      end
    end
  end

  describe '.read' do
    subject(:result) do
      described_class.read(
        network: network,
        contract_address: contract_address,
        method: method_name,
        abi: abi,
        args: args
      )
    end

    let(:contract_address) { '0x1234567890123456789012345678901234567890' }
    let(:method_name) { 'testMethod' }
    let(:abi) { [{ 'name' => 'testMethod', 'inputs' => [], 'outputs' => [] }] }
    let(:args) { { 'value' => 123 } }
    let(:expected_params) { { method: method_name, abi: abi.to_json, args: args.to_json } }

    before do
      allow(smart_contracts_api).to receive(:read_contract)
    end

    it 'calls read_contract with correct parameters' do
      result
      expect(smart_contracts_api).to have_received(:read_contract)
        .with(network.normalized_id, contract_address, hash_including(expected_params))
    end

    context 'when using a different network' do
      let(:network_id) { :ethereum_mainnet }

      it 'calls read_contract with the normalized network ID' do
        result

        expect(smart_contracts_api)
          .to have_received(:read_contract)
          .with(
            'ethereum-mainnet',
            contract_address,
            anything
          )
      end
    end

    context 'when using the default network' do
      subject(:result) do
        described_class.read(
          contract_address: contract_address,
          method: method_name,
          abi: abi,
          args: args
        )
      end

      it 'calls read_contract with correct parameters' do
        result
        expect(smart_contracts_api).to have_received(:read_contract)
          .with(default_network.normalized_id, contract_address, expected_params)
      end
    end

    context 'when using a different contract address' do
      let(:contract_address) { '0x9876543210987654321098765432109876543210' }

      it 'calls read_contract with the provided address' do
        result

        expect(smart_contracts_api)
          .to have_received(:read_contract)
          .with(
            anything,
            contract_address,
            anything
          )
      end
    end

    context 'when using a different method name' do
      let(:method_name) { 'differentMethod' }

      it 'calls read_contract with the provided method' do
        result

        expect(smart_contracts_api)
          .to have_received(:read_contract)
          .with(
            anything,
            anything,
            hash_including(method: method_name)
          )
      end
    end

    context 'when args parameter is nil' do
      let(:args) { nil }

      it 'calls read_contract with null args' do
        result

        expect(smart_contracts_api)
          .to have_received(:read_contract)
          .with(
            anything,
            anything,
            hash_including(args: '{}')
          )
      end
    end

    context 'when args parameter is omitted' do
      subject(:result) do
        described_class.read(
          network: network,
          contract_address: contract_address,
          method: method_name,
          abi: abi
        )
      end

      it 'calls read_contract with empty args object' do
        result

        expect(smart_contracts_api)
          .to have_received(:read_contract)
          .with(
            anything,
            anything,
            hash_including(args: '{}')
          )
      end
    end

    context 'when ABI parameter is nil' do
      let(:abi) { nil }
      let(:expected_params) do
        {
          method: method_name,
          args: args.to_json
        }
      end

      it 'calls read_contract without an ABI' do
        result

        expect(smart_contracts_api).to have_received(:read_contract)
          .with(network.normalized_id, contract_address, hash_including(expected_params))
      end
    end

    context 'when ABI parameter is omitted' do
      subject(:result) do
        described_class.read(
          network: network,
          contract_address: contract_address,
          method: method_name,
          args: args
        )
      end

      let(:expected_params) do
        {
          method: method_name,
          args: args.to_json
        }
      end

      it 'calls read_contract without an ABI' do
        result

        expect(smart_contracts_api).to have_received(:read_contract)
          .with(network.normalized_id, contract_address, expected_params)
      end
    end

    def build_nested_solidity_value(hash)
      return hash unless hash.is_a?(Hash)

      values = hash[:values]&.map do |v|
        v.is_a?(Hash) ? build_nested_solidity_value(v) : v
      end

      attrs = hash.merge(
        values: values
      ).compact

      Coinbase::Client::SolidityValue.new(**attrs)
    end

    [
      {
        test: 'uint8',
        method_name: 'pureUint8',
        solidity_value: { type: 'uint8', value: '123' },
        expected_value: 123
      },
      {
        test: 'uint16',
        method_name: 'pureUint16',
        solidity_value: { type: 'uint16', value: '12345' },
        expected_value: 12_345
      },
      {
        test: 'uint32',
        method_name: 'pureUint32',
        solidity_value: { type: 'uint32', value: '4294967295' },
        expected_value: 4_294_967_295
      },
      {
        test: 'uint64',
        method_name: 'pureUint64',
        solidity_value: { type: 'uint64', value: '18446744073709551615' },
        expected_value: 18_446_744_073_709_551_615
      },
      {
        test: 'uint128',
        method_name: 'pureUint128',
        solidity_value: { type: 'uint128', value: '340282366920938463463374607431768211455' },
        expected_value: 340_282_366_920_938_463_463_374_607_431_768_211_455
      },
      {
        test: 'uint256',
        method_name: 'pureUint256',
        solidity_value: {
          type: 'uint256',
          value: '115792089237316195423570985008687907853269984665640564039457584007913129639935'
        },
        expected_value:
            115_792_089_237_316_195_423_570_985_008_687_907_853_269_984_665_640_564_039_457_584_007_913_129_639_935
      },
      {
        test: 'int8',
        method_name: 'pureInt8',
        solidity_value: { type: 'int8', value: '-128' },
        expected_value: -128
      },
      {
        test: 'int16',
        method_name: 'pureInt16',
        solidity_value: { type: 'int16', value: '-32768' },
        expected_value: -32_768
      },
      {
        test: 'int32',
        method_name: 'pureInt32',
        solidity_value: { type: 'int32', value: '-2147483648' },
        expected_value: -2_147_483_648
      },
      {
        test: 'int64',
        method_name: 'pureInt64',
        solidity_value: { type: 'int64', value: '-9223372036854775808' },
        expected_value: -9_223_372_036_854_775_808
      },
      {
        test: 'int128',
        method_name: 'pureInt128',
        solidity_value: { type: 'int128', value: '-170141183460469231731687303715884105728' },
        expected_value: -170_141_183_460_469_231_731_687_303_715_884_105_728
      },
      {
        test: 'int256',
        method_name: 'pureInt256',
        solidity_value: {
          type: 'int256',
          value: '-57896044618658097711785492504343953926634992332820282019728792003956564819968'
        },
        expected_value:
          -57_896_044_618_658_097_711_785_492_504_343_953_926_634_992_332_820_282_019_728_792_003_956_564_819_968
      },
      {
        test: 'address',
        method_name: 'pureAddress',
        solidity_value: {
          type: 'address',
          value: '0x742d35Cc6634C0532925a3b844Bc454e4438f44e'
        },
        expected_value: '0x742d35Cc6634C0532925a3b844Bc454e4438f44e'
      },
      {
        test: 'string',
        method_name: 'pureString',
        solidity_value: { type: 'string', value: 'Hello, World!' },
        expected_value: 'Hello, World!'
      },
      {
        test: 'boolean true',
        method_name: 'pureBool',
        solidity_value: { type: 'bool', value: 'true' },
        expected_value: true
      },
      {
        test: 'boolean false',
        method_name: 'pureBool',
        solidity_value: { type: 'bool', value: 'false' },
        expected_value: false
      },
      {
        test: 'function',
        method_name: 'returnFunction',
        solidity_value: { type: 'bytes', value: '0x12341234123412341234123400000000' },
        expected_value: '0x12341234123412341234123400000000'
      },
      {
        test: 'array',
        method_name: 'pureArray',
        solidity_value: {
          type: 'array',
          values: [
            { type: 'uint256', value: '1' },
            { type: 'uint256', value: '2' },
            { type: 'uint256', value: '3' }
          ]
        },
        expected_value: [1, 2, 3]
      },
      {
        test: 'simple tuple',
        method_name: 'pureTuple',
        solidity_value: {
          type: 'tuple',
          values: [
            { type: 'uint256', name: 'a', value: '1' },
            { type: 'uint256', name: 'b', value: '2' }
          ]
        },
        expected_value: { 'a' => 1, 'b' => 2 }
      },
      {
        test: 'mixed tuple',
        method_name: 'pureTupleMixedTypes',
        solidity_value: {
          type: 'tuple',
          values: [
            { type: 'uint256', name: 'a', value: '1' },
            { type: 'address', name: 'b', value: '0x1234567890123456789012345678901234567890' },
            { type: 'bool', name: 'c', value: 'true' }
          ]
        },
        expected_value: {
          'a' => 1,
          'b' => '0x1234567890123456789012345678901234567890',
          'c' => true
        }
      },
      {
        test: 'nested tuple',
        method_name: 'pureNestedStruct',
        solidity_value: {
          type: 'tuple',
          values: [
            { type: 'uint256', name: 'a', value: '123' },
            {
              type: 'tuple',
              name: 'nestedFields',
              values: [
                {
                  type: 'tuple',
                  name: 'nestedArray',
                  values: [
                    {
                      type: 'array',
                      name: 'a',
                      values: [
                        { type: 'uint256', value: '1' },
                        { type: 'uint256', value: '2' },
                        { type: 'uint256', value: '3' }
                      ]
                    }
                  ]
                },
                { type: 'uint256', name: 'a', value: '456' }
              ]
            }
          ]
        },
        expected_value: {
          'a' => 123,
          'nestedFields' => {
            'nestedArray' => {
              'a' => [1, 2, 3]
            },
            'a' => 456
          }
        }
      }
    ].each do |test_case|
      context "when the return value is #{test_case[:test]}" do
        before do
          solidity_value = build_nested_solidity_value(test_case[:solidity_value])
          allow(smart_contracts_api).to receive(:read_contract).and_return(solidity_value)
        end

        it "returns the parsed #{test_case[:test]} value" do
          expect(result).to eq(test_case[:expected_value])
        end
      end
    end

    # Fixed-size Bytes Tests (bytes1 through bytes32)
    32.times do |i|
      size = i + 1
      hex_value = "0x#{'01' * size}"

      test_case = {
        test: "bytes#{size}",
        method_name: "pureBytes#{size}",
        solidity_value: { type: "bytes#{size}", value: hex_value },
        expected_value: hex_value
      }

      context "when the return value is #{test_case[:test]}" do
        before do
          solidity_value = build_nested_solidity_value(test_case[:solidity_value])
          allow(smart_contracts_api).to receive(:read_contract).and_return(solidity_value)
        end

        it "returns the parsed #{test_case[:test]} value" do
          expect(result).to eq(test_case[:expected_value])
        end
      end
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
    it 'includes smart contract details' do
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
