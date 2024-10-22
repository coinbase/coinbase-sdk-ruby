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
    let(:method_name) { method_name_for_context }
    let(:args) { {} }
    let(:abi) { nil }

    describe 'API interaction' do
      let(:method_name_for_context) { 'testMethod' }
      let(:abi) do
        [{
          'type' => 'function',
          'name' => 'testMethod',
          'inputs' => [],
          'outputs' => [{ 'type' => 'uint256' }],
          'stateMutability' => 'pure'
        }]
      end

      before do
        allow(smart_contracts_api).to receive(:read_contract).and_return(
          Coinbase::Client::SolidityValue.new({
                                                'type' => 'uint256',
                                                'value' => '0'
                                              })
        )
      end

      it 'calls the API with correct network' do
        result
        expect(smart_contracts_api).to have_received(:read_contract)
          .with('base-sepolia', anything, anything)
      end

      it 'calls the API with correct address' do
        result
        expect(smart_contracts_api).to have_received(:read_contract)
          .with(anything, contract_address, anything)
      end

      it 'calls the API with correct method' do
        result
        expect(smart_contracts_api).to have_received(:read_contract)
          .with(anything, anything, have_attributes(method: method_name))
      end

      it 'calls the API with correct ABI' do
        result
        expect(smart_contracts_api).to have_received(:read_contract)
          .with(anything, anything, have_attributes(abi: abi.to_json))
      end

      it 'calls the API with correct arguments' do
        result
        expect(smart_contracts_api).to have_received(:read_contract)
          .with(anything, anything, have_attributes(args: args.to_json))
      end
    end

    describe 'abi parameter' do
      let(:method_name_for_context) { 'testMethod' }

      before do
        allow(smart_contracts_api).to receive(:read_contract).and_return(
          Coinbase::Client::SolidityValue.new({
                                                'type' => 'uint256',
                                                'value' => '0'
                                              })
        )
      end

      describe 'when explicitly set to nil' do
        let(:abi) { nil }

        it 'sends the request with null abi' do
          result
          expect(smart_contracts_api).to have_received(:read_contract)
            .with(anything, anything, have_attributes(abi: nil))
        end
      end

      describe 'when omitted' do
        subject(:result) do
          described_class.read(
            network: network,
            contract_address: contract_address,
            method: method_name
          )
        end

        it 'sends the request with null abi' do
          result
          expect(smart_contracts_api).to have_received(:read_contract)
            .with(anything, anything, have_attributes(abi: nil))
        end
      end

      describe 'when provided' do
        let(:abi) do
          [{
            'type' => 'function',
            'name' => 'testMethod',
            'inputs' => [],
            'outputs' => [{ 'type' => 'uint256' }],
            'stateMutability' => 'pure'
          }]
        end

        it 'sends the request with JSON encoded abi' do
          result
          expect(smart_contracts_api).to have_received(:read_contract)
            .with(anything, anything, have_attributes(abi: abi.to_json))
        end
      end
    end

    describe 'args parameter' do
      let(:method_name_for_context) { 'testMethod' }

      before do
        allow(smart_contracts_api).to receive(:read_contract).and_return(
          Coinbase::Client::SolidityValue.new({
                                                'type' => 'uint256',
                                                'value' => '0'
                                              })
        )
      end

      describe 'when explicitly set to nil' do
        let(:args) { nil }

        it 'sends the request with "null" args' do
          result
          expect(smart_contracts_api).to have_received(:read_contract)
            .with(anything, anything, have_attributes(args: 'null'))
        end
      end

      describe 'when omitted' do
        subject(:result) do
          described_class.read(
            network: network,
            contract_address: contract_address,
            method: method_name,
            abi: abi
          )
        end

        it 'sends the request with empty hash JSON args' do
          result
          expect(smart_contracts_api).to have_received(:read_contract)
            .with(anything, anything, have_attributes(args: {}.to_json))
        end
      end

      describe 'when provided as a hash' do
        let(:args) { { 'value' => 123 } }

        it 'sends the request with JSON encoded args' do
          result
          expect(smart_contracts_api).to have_received(:read_contract)
            .with(anything, anything, have_attributes(args: args.to_json))
        end
      end
    end

    describe 'uint types' do
      describe 'uint8' do
        let(:method_name_for_context) { 'getUint8' }

        before do
          allow(smart_contracts_api).to receive(:read_contract).and_return(
            Coinbase::Client::SolidityValue.new({
                                                  'type' => 'uint8',
                                                  'value' => '255'
                                                })
          )
        end

        it 'returns the parsed uint8 value' do
          expect(result).to eq(255)
        end
      end

      describe 'uint16' do
        let(:method_name_for_context) { 'getUint16' }

        before do
          allow(smart_contracts_api).to receive(:read_contract).and_return(
            Coinbase::Client::SolidityValue.new({
                                                  'type' => 'uint16',
                                                  'value' => '65535'
                                                })
          )
        end

        it 'returns the parsed uint16 value' do
          expect(result).to eq(65_535)
        end
      end

      describe 'uint32' do
        let(:method_name_for_context) { 'getUint32' }

        before do
          allow(smart_contracts_api).to receive(:read_contract).and_return(
            Coinbase::Client::SolidityValue.new({
                                                  'type' => 'uint32',
                                                  'value' => '4294967295'
                                                })
          )
        end

        it 'returns the parsed uint32 value' do
          expect(result).to eq(4_294_967_295)
        end
      end

      describe 'uint64' do
        let(:method_name_for_context) { 'getUint64' }

        before do
          allow(smart_contracts_api).to receive(:read_contract).and_return(
            Coinbase::Client::SolidityValue.new({
                                                  'type' => 'uint64',
                                                  'value' => '18446744073709551615'
                                                })
          )
        end

        it 'returns the parsed uint64 value' do
          expect(result).to eq(18_446_744_073_709_551_615)
        end
      end

      describe 'uint128' do
        let(:method_name_for_context) { 'getUint128' }

        before do
          allow(smart_contracts_api).to receive(:read_contract).and_return(
            Coinbase::Client::SolidityValue.new({
                                                  'type' => 'uint128',
                                                  'value' => '340282366920938463463374607431768211455'
                                                })
          )
        end

        it 'returns the parsed uint128 value' do
          expect(result).to eq(340_282_366_920_938_463_463_374_607_431_768_211_455)
        end
      end

      describe 'uint256' do
        let(:method_name_for_context) { 'getUint256' }
        let(:uint256_max) do
          '115792089237316195423570985008687907853269984665640564039457584007913129639935'
        end

        before do
          allow(smart_contracts_api).to receive(:read_contract).and_return(
            Coinbase::Client::SolidityValue.new({
                                                  'type' => 'uint256',
                                                  'value' => uint256_max
                                                })
          )
        end

        it 'returns the parsed uint256 value' do
          max_value =
            115_792_089_237_316_195_423_570_985_008_687_907_853_269_984_665_640_564_039_457_584_007_913_129_639_935
          expect(result).to eq(max_value)
        end
      end
    end

    describe 'int types' do
      describe 'int8' do
        let(:method_name_for_context) { 'getInt8' }

        before do
          allow(smart_contracts_api).to receive(:read_contract).and_return(
            Coinbase::Client::SolidityValue.new({
                                                  'type' => 'int8',
                                                  'value' => '-128'
                                                })
          )
        end

        it 'returns the parsed int8 value' do
          expect(result).to eq(-128)
        end
      end

      describe 'int16' do
        let(:method_name_for_context) { 'getInt16' }

        before do
          allow(smart_contracts_api).to receive(:read_contract).and_return(
            Coinbase::Client::SolidityValue.new({
                                                  'type' => 'int16',
                                                  'value' => '-32768'
                                                })
          )
        end

        it 'returns the parsed int16 value' do
          expect(result).to eq(-32_768)
        end
      end

      describe 'int32' do
        let(:method_name_for_context) { 'getInt32' }

        before do
          allow(smart_contracts_api).to receive(:read_contract).and_return(
            Coinbase::Client::SolidityValue.new({
                                                  'type' => 'int32',
                                                  'value' => '-2147483648'
                                                })
          )
        end

        it 'returns the parsed int32 value' do
          expect(result).to eq(-2_147_483_648)
        end
      end

      describe 'int64' do
        let(:method_name_for_context) { 'getInt64' }

        before do
          allow(smart_contracts_api).to receive(:read_contract).and_return(
            Coinbase::Client::SolidityValue.new({
                                                  'type' => 'int64',
                                                  'value' => '-9223372036854775808'
                                                })
          )
        end

        it 'returns the parsed int64 value' do
          expect(result).to eq(-9_223_372_036_854_775_808)
        end
      end

      describe 'int128' do
        let(:method_name_for_context) { 'getInt128' }

        before do
          allow(smart_contracts_api).to receive(:read_contract).and_return(
            Coinbase::Client::SolidityValue.new({
                                                  'type' => 'int128',
                                                  'value' => '-170141183460469231731687303715884105728'
                                                })
          )
        end

        it 'returns the parsed int128 value' do
          expect(result).to eq(-170_141_183_460_469_231_731_687_303_715_884_105_728)
        end
      end

      describe 'int256' do
        let(:method_name_for_context) { 'getInt256' }
        let(:int256_min) do
          '-57896044618658097711785492504343953926634992332820282019728792003956564819968'
        end

        before do
          allow(smart_contracts_api).to receive(:read_contract).and_return(
            Coinbase::Client::SolidityValue.new({
                                                  'type' => 'int256',
                                                  'value' => int256_min
                                                })
          )
        end

        it 'returns the parsed int256 value' do
          min_value =
            -57_896_044_618_658_097_711_785_492_504_343_953_926_634_992_332_820_282_019_728_792_003_956_564_819_968
          expect(result).to eq(min_value)
        end
      end
    end

    describe 'boolean type' do
      let(:method_name_for_context) { 'pureBool' }

      before do
        allow(smart_contracts_api).to receive(:read_contract).and_return(
          Coinbase::Client::SolidityValue.new({
                                                'type' => 'bool',
                                                'value' => 'true'
                                              })
        )
      end

      it 'returns the parsed boolean value' do
        expect(result).to be(true)
      end
    end

    describe 'address type' do
      let(:method_name_for_context) { 'pureAddress' }
      let(:address) { '0xd8da6bf26964af9d7eed9e03e53415d37aa96045' }

      before do
        allow(smart_contracts_api).to receive(:read_contract).and_return(
          Coinbase::Client::SolidityValue.new({
                                                'type' => 'address',
                                                'value' => address
                                              })
        )
      end

      it 'returns the parsed address value' do
        expect(result).to eq(address)
      end
    end

    describe 'array type' do
      let(:method_name_for_context) { 'pureArray' }

      before do
        allow(smart_contracts_api).to receive(:read_contract).and_return(
          Coinbase::Client::SolidityValue.new({
                                                'type' => 'array',
                                                'values' => [
                                                  Coinbase::Client::SolidityValue.new({
                                                                                        'type' => 'uint256',
                                                                                        'value' => '1'
                                                                                      }),
                                                  Coinbase::Client::SolidityValue.new({
                                                                                        'type' => 'uint256',
                                                                                        'value' => '2'
                                                                                      }),
                                                  Coinbase::Client::SolidityValue.new({
                                                                                        'type' => 'uint256',
                                                                                        'value' => '3'
                                                                                      })
                                                ]
                                              })
        )
      end

      it 'returns the parsed array values' do
        expect(result).to eq([1, 2, 3])
      end
    end

    describe 'fixed bytes types' do
      describe 'bytes1' do
        let(:method_name_for_context) { 'pureBytes1' }
        let(:bytes_value) { '0x01' }

        before do
          allow(smart_contracts_api).to receive(:read_contract).and_return(
            Coinbase::Client::SolidityValue.new({
                                                  'type' => 'bytes1',
                                                  'value' => bytes_value
                                                })
          )
        end

        it 'returns the parsed fixed bytes value' do
          expect(result).to eq(bytes_value)
        end
      end

      describe 'bytes2' do
        let(:method_name_for_context) { 'pureBytes2' }
        let(:bytes_value) { '0x0102' }

        before do
          allow(smart_contracts_api).to receive(:read_contract).and_return(
            Coinbase::Client::SolidityValue.new({
                                                  'type' => 'bytes2',
                                                  'value' => bytes_value
                                                })
          )
        end

        it 'returns the parsed fixed bytes value' do
          expect(result).to eq(bytes_value)
        end
      end

      describe 'bytes3' do
        let(:method_name_for_context) { 'pureBytes3' }
        let(:bytes_value) { '0x010203' }

        before do
          allow(smart_contracts_api).to receive(:read_contract).and_return(
            Coinbase::Client::SolidityValue.new({
                                                  'type' => 'bytes3',
                                                  'value' => bytes_value
                                                })
          )
        end

        it 'returns the parsed fixed bytes value' do
          expect(result).to eq(bytes_value)
        end
      end

      describe 'bytes4' do
        let(:method_name_for_context) { 'pureBytes4' }
        let(:bytes_value) { '0x01020304' }

        before do
          allow(smart_contracts_api).to receive(:read_contract).and_return(
            Coinbase::Client::SolidityValue.new({
                                                  'type' => 'bytes4',
                                                  'value' => bytes_value
                                                })
          )
        end

        it 'returns the parsed fixed bytes value' do
          expect(result).to eq(bytes_value)
        end
      end

      describe 'bytes5' do
        let(:method_name_for_context) { 'pureBytes5' }
        let(:bytes_value) { '0x0102030405' }

        before do
          allow(smart_contracts_api).to receive(:read_contract).and_return(
            Coinbase::Client::SolidityValue.new({
                                                  'type' => 'bytes5',
                                                  'value' => bytes_value
                                                })
          )
        end

        it 'returns the parsed fixed bytes value' do
          expect(result).to eq(bytes_value)
        end
      end

      describe 'bytes6' do
        let(:method_name_for_context) { 'pureBytes6' }
        let(:bytes_value) { '0x010203040506' }

        before do
          allow(smart_contracts_api).to receive(:read_contract).and_return(
            Coinbase::Client::SolidityValue.new({
                                                  'type' => 'bytes6',
                                                  'value' => bytes_value
                                                })
          )
        end

        it 'returns the parsed fixed bytes value' do
          expect(result).to eq(bytes_value)
        end
      end

      describe 'bytes7' do
        let(:method_name_for_context) { 'pureBytes7' }
        let(:bytes_value) { '0x01020304050607' }

        before do
          allow(smart_contracts_api).to receive(:read_contract).and_return(
            Coinbase::Client::SolidityValue.new({
                                                  'type' => 'bytes7',
                                                  'value' => bytes_value
                                                })
          )
        end

        it 'returns the parsed fixed bytes value' do
          expect(result).to eq(bytes_value)
        end
      end

      describe 'bytes8' do
        let(:method_name_for_context) { 'pureBytes8' }
        let(:bytes_value) { '0x0102030405060708' }

        before do
          allow(smart_contracts_api).to receive(:read_contract).and_return(
            Coinbase::Client::SolidityValue.new({
                                                  'type' => 'bytes8',
                                                  'value' => bytes_value
                                                })
          )
        end

        it 'returns the parsed fixed bytes value' do
          expect(result).to eq(bytes_value)
        end
      end

      describe 'bytes9' do
        let(:method_name_for_context) { 'pureBytes9' }
        let(:bytes_value) { '0x010203040506070809' }

        before do
          allow(smart_contracts_api).to receive(:read_contract).and_return(
            Coinbase::Client::SolidityValue.new({
                                                  'type' => 'bytes9',
                                                  'value' => bytes_value
                                                })
          )
        end

        it 'returns the parsed fixed bytes value' do
          expect(result).to eq(bytes_value)
        end
      end

      describe 'bytes10' do
        let(:method_name_for_context) { 'pureBytes10' }
        let(:bytes_value) { '0x0102030405060708090a' }

        before do
          allow(smart_contracts_api).to receive(:read_contract).and_return(
            Coinbase::Client::SolidityValue.new({
                                                  'type' => 'bytes10',
                                                  'value' => bytes_value
                                                })
          )
        end

        it 'returns the parsed fixed bytes value' do
          expect(result).to eq(bytes_value)
        end
      end

      describe 'bytes11' do
        let(:method_name_for_context) { 'pureBytes11' }
        let(:bytes_value) { '0x0102030405060708090a0b' }

        before do
          allow(smart_contracts_api).to receive(:read_contract).and_return(
            Coinbase::Client::SolidityValue.new({
                                                  'type' => 'bytes11',
                                                  'value' => bytes_value
                                                })
          )
        end

        it 'returns the parsed fixed bytes value' do
          expect(result).to eq(bytes_value)
        end
      end

      describe 'bytes12' do
        let(:method_name_for_context) { 'pureBytes12' }
        let(:bytes_value) { '0x0102030405060708090a0b0c' }

        before do
          allow(smart_contracts_api).to receive(:read_contract).and_return(
            Coinbase::Client::SolidityValue.new({
                                                  'type' => 'bytes12',
                                                  'value' => bytes_value
                                                })
          )
        end

        it 'returns the parsed fixed bytes value' do
          expect(result).to eq(bytes_value)
        end
      end

      describe 'bytes13' do
        let(:method_name_for_context) { 'pureBytes13' }
        let(:bytes_value) { '0x0102030405060708090a0b0c0d' }

        before do
          allow(smart_contracts_api).to receive(:read_contract).and_return(
            Coinbase::Client::SolidityValue.new({
                                                  'type' => 'bytes13',
                                                  'value' => bytes_value
                                                })
          )
        end

        it 'returns the parsed fixed bytes value' do
          expect(result).to eq(bytes_value)
        end
      end

      describe 'bytes14' do
        let(:method_name_for_context) { 'pureBytes14' }
        let(:bytes_value) { '0x0102030405060708090a0b0c0d0e' }

        before do
          allow(smart_contracts_api).to receive(:read_contract).and_return(
            Coinbase::Client::SolidityValue.new({
                                                  'type' => 'bytes14',
                                                  'value' => bytes_value
                                                })
          )
        end

        it 'returns the parsed fixed bytes value' do
          expect(result).to eq(bytes_value)
        end
      end

      describe 'bytes15' do
        let(:method_name_for_context) { 'pureBytes15' }
        let(:bytes_value) { '0x0102030405060708090a0b0c0d0e0f' }

        before do
          allow(smart_contracts_api).to receive(:read_contract).and_return(
            Coinbase::Client::SolidityValue.new({
                                                  'type' => 'bytes15',
                                                  'value' => bytes_value
                                                })
          )
        end

        it 'returns the parsed fixed bytes value' do
          expect(result).to eq(bytes_value)
        end
      end

      describe 'bytes16' do
        let(:method_name_for_context) { 'pureBytes16' }
        let(:bytes_value) { '0x0102030405060708090a0b0c0d0e0f10' }

        before do
          allow(smart_contracts_api).to receive(:read_contract).and_return(
            Coinbase::Client::SolidityValue.new({
                                                  'type' => 'bytes16',
                                                  'value' => bytes_value
                                                })
          )
        end

        it 'returns the parsed fixed bytes value' do
          expect(result).to eq(bytes_value)
        end
      end

      describe 'bytes17' do
        let(:method_name_for_context) { 'pureBytes17' }
        let(:bytes_value) { '0x0102030405060708090a0b0c0d0e0f1011' }

        before do
          allow(smart_contracts_api).to receive(:read_contract).and_return(
            Coinbase::Client::SolidityValue.new({
                                                  'type' => 'bytes17',
                                                  'value' => bytes_value
                                                })
          )
        end

        it 'returns the parsed fixed bytes value' do
          expect(result).to eq(bytes_value)
        end
      end

      describe 'bytes18' do
        let(:method_name_for_context) { 'pureBytes18' }
        let(:bytes_value) { '0x0102030405060708090a0b0c0d0e0f101112' }

        before do
          allow(smart_contracts_api).to receive(:read_contract).and_return(
            Coinbase::Client::SolidityValue.new({
                                                  'type' => 'bytes18',
                                                  'value' => bytes_value
                                                })
          )
        end

        it 'returns the parsed fixed bytes value' do
          expect(result).to eq(bytes_value)
        end
      end

      describe 'bytes19' do
        let(:method_name_for_context) { 'pureBytes19' }
        let(:bytes_value) { '0x0102030405060708090a0b0c0d0e0f10111213' }

        before do
          allow(smart_contracts_api).to receive(:read_contract).and_return(
            Coinbase::Client::SolidityValue.new({
                                                  'type' => 'bytes19',
                                                  'value' => bytes_value
                                                })
          )
        end

        it 'returns the parsed fixed bytes value' do
          expect(result).to eq(bytes_value)
        end
      end

      describe 'bytes20' do
        let(:method_name_for_context) { 'pureBytes20' }
        let(:bytes_value) { '0x0102030405060708090a0b0c0d0e0f1011121314' }

        before do
          allow(smart_contracts_api).to receive(:read_contract).and_return(
            Coinbase::Client::SolidityValue.new({
                                                  'type' => 'bytes20',
                                                  'value' => bytes_value
                                                })
          )
        end

        it 'returns the parsed fixed bytes value' do
          expect(result).to eq(bytes_value)
        end
      end

      describe 'bytes21' do
        let(:method_name_for_context) { 'pureBytes21' }
        let(:bytes_value) { '0x0102030405060708090a0b0c0d0e0f101112131415' }

        before do
          allow(smart_contracts_api).to receive(:read_contract).and_return(
            Coinbase::Client::SolidityValue.new({
                                                  'type' => 'bytes21',
                                                  'value' => bytes_value
                                                })
          )
        end

        it 'returns the parsed fixed bytes value' do
          expect(result).to eq(bytes_value)
        end
      end

      describe 'bytes22' do
        let(:method_name_for_context) { 'pureBytes22' }
        let(:bytes_value) { '0x0102030405060708090a0b0c0d0e0f10111213141516' }

        before do
          allow(smart_contracts_api).to receive(:read_contract).and_return(
            Coinbase::Client::SolidityValue.new({
                                                  'type' => 'bytes22',
                                                  'value' => bytes_value
                                                })
          )
        end

        it 'returns the parsed fixed bytes value' do
          expect(result).to eq(bytes_value)
        end
      end

      describe 'bytes23' do
        let(:method_name_for_context) { 'pureBytes23' }
        let(:bytes_value) { '0x0102030405060708090a0b0c0d0e0f1011121314151617' }

        before do
          allow(smart_contracts_api).to receive(:read_contract).and_return(
            Coinbase::Client::SolidityValue.new({
                                                  'type' => 'bytes23',
                                                  'value' => bytes_value
                                                })
          )
        end

        it 'returns the parsed fixed bytes value' do
          expect(result).to eq(bytes_value)
        end
      end

      describe 'bytes24' do
        let(:method_name_for_context) { 'pureBytes24' }
        let(:bytes_value) { '0x0102030405060708090a0b0c0d0e0f101112131415161718' }

        before do
          allow(smart_contracts_api).to receive(:read_contract).and_return(
            Coinbase::Client::SolidityValue.new({
                                                  'type' => 'bytes24',
                                                  'value' => bytes_value
                                                })
          )
        end

        it 'returns the parsed fixed bytes value' do
          expect(result).to eq(bytes_value)
        end
      end

      describe 'bytes25' do
        let(:method_name_for_context) { 'pureBytes25' }
        let(:bytes_value) { '0x0102030405060708090a0b0c0d0e0f10111213141516171819' }

        before do
          allow(smart_contracts_api).to receive(:read_contract).and_return(
            Coinbase::Client::SolidityValue.new({
                                                  'type' => 'bytes25',
                                                  'value' => bytes_value
                                                })
          )
        end

        it 'returns the parsed fixed bytes value' do
          expect(result).to eq(bytes_value)
        end
      end

      describe 'bytes26' do
        let(:method_name_for_context) { 'pureBytes26' }
        let(:bytes_value) { '0x0102030405060708090a0b0c0d0e0f101112131415161718191a' }

        before do
          allow(smart_contracts_api).to receive(:read_contract).and_return(
            Coinbase::Client::SolidityValue.new({
                                                  'type' => 'bytes26',
                                                  'value' => bytes_value
                                                })
          )
        end

        it 'returns the parsed fixed bytes value' do
          expect(result).to eq(bytes_value)
        end
      end

      describe 'bytes27' do
        let(:method_name_for_context) { 'pureBytes27' }
        let(:bytes_value) { '0x0102030405060708090a0b0c0d0e0f101112131415161718191a1b' }

        before do
          allow(smart_contracts_api).to receive(:read_contract).and_return(
            Coinbase::Client::SolidityValue.new({
                                                  'type' => 'bytes27',
                                                  'value' => bytes_value
                                                })
          )
        end

        it 'returns the parsed fixed bytes value' do
          expect(result).to eq(bytes_value)
        end
      end

      describe 'bytes28' do
        let(:method_name_for_context) { 'pureBytes28' }
        let(:bytes_value) { '0x0102030405060708090a0b0c0d0e0f101112131415161718191a1b1c' }

        before do
          allow(smart_contracts_api).to receive(:read_contract).and_return(
            Coinbase::Client::SolidityValue.new({
                                                  'type' => 'bytes28',
                                                  'value' => bytes_value
                                                })
          )
        end

        it 'returns the parsed fixed bytes value' do
          expect(result).to eq(bytes_value)
        end
      end

      describe 'bytes29' do
        let(:method_name_for_context) { 'pureBytes29' }
        let(:bytes_value) { '0x0102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d' }

        before do
          allow(smart_contracts_api).to receive(:read_contract).and_return(
            Coinbase::Client::SolidityValue.new({
                                                  'type' => 'bytes29',
                                                  'value' => bytes_value
                                                })
          )
        end

        it 'returns the parsed fixed bytes value' do
          expect(result).to eq(bytes_value)
        end
      end

      describe 'bytes30' do
        let(:method_name_for_context) { 'pureBytes30' }
        let(:bytes_value) { '0x0102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e' }

        before do
          allow(smart_contracts_api).to receive(:read_contract).and_return(
            Coinbase::Client::SolidityValue.new({
                                                  'type' => 'bytes30',
                                                  'value' => bytes_value
                                                })
          )
        end

        it 'returns the parsed fixed bytes value' do
          expect(result).to eq(bytes_value)
        end
      end

      describe 'bytes31' do
        let(:method_name_for_context) { 'pureBytes31' }
        let(:bytes_value) { '0x0102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f' }

        before do
          allow(smart_contracts_api).to receive(:read_contract).and_return(
            Coinbase::Client::SolidityValue.new({
                                                  'type' => 'bytes31',
                                                  'value' => bytes_value
                                                })
          )
        end

        it 'returns the parsed fixed bytes value' do
          expect(result).to eq(bytes_value)
        end
      end

      describe 'bytes32' do
        let(:method_name_for_context) { 'pureBytes32' }
        let(:bytes_value) { '0x0102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f20' }

        before do
          allow(smart_contracts_api).to receive(:read_contract).and_return(
            Coinbase::Client::SolidityValue.new({
                                                  'type' => 'bytes32',
                                                  'value' => bytes_value
                                                })
          )
        end

        it 'returns the parsed fixed bytes value' do
          expect(result).to eq(bytes_value)
        end
      end
    end

    describe 'dynamic bytes type' do
      let(:method_name_for_context) { 'pureBytes' }
      let(:bytes_value) { '0x0102030405' }

      before do
        allow(smart_contracts_api).to receive(:read_contract).and_return(
          Coinbase::Client::SolidityValue.new({
                                                'type' => 'bytes',
                                                'value' => bytes_value
                                              })
        )
      end

      it 'returns the parsed dynamic bytes value' do
        expect(result).to eq(bytes_value)
      end
    end

    describe 'string type' do
      let(:method_name_for_context) { 'pureString' }

      before do
        allow(smart_contracts_api).to receive(:read_contract).and_return(
          Coinbase::Client::SolidityValue.new({
                                                'type' => 'string',
                                                'value' => 'Hello, World!'
                                              })
        )
      end

      it 'returns the parsed string value' do
        expect(result).to eq('Hello, World!')
      end
    end

    describe 'function type' do
      let(:method_name_for_context) { 'returnFunction' }
      let(:function_bytes) { '0x12341234123412341234123400000000' }

      before do
        allow(smart_contracts_api).to receive(:read_contract).and_return(
          Coinbase::Client::SolidityValue.new({
                                                'type' => 'bytes',
                                                'value' => function_bytes
                                              })
        )
      end

      it 'returns the function as bytes value' do
        expect(result).to eq(function_bytes)
      end
    end

    describe 'tuple type' do
      let(:method_name_for_context) { 'pureTuple' }

      before do
        allow(smart_contracts_api).to receive(:read_contract).and_return(
          Coinbase::Client::SolidityValue.new(
            'type' => 'tuple',
            'values' => [
              Coinbase::Client::SolidityValue.new({
                                                    'type' => 'uint256',
                                                    'name' => 'a',
                                                    'value' => '1'
                                                  }),
              Coinbase::Client::SolidityValue.new({
                                                    'type' => 'uint256',
                                                    'name' => 'b',
                                                    'value' => '2'
                                                  })
            ]
          )
        )
      end

      it 'returns the parsed tuple value' do
        expect(result).to eq({ 'a' => 1, 'b' => 2 })
      end
    end

    describe 'tuple with mixed types' do
      let(:method_name_for_context) { 'pureTupleMixedTypes' }
      let(:address) { '0x1234567890123456789012345678901234567890' }

      before do
        allow(smart_contracts_api).to receive(:read_contract).and_return(
          Coinbase::Client::SolidityValue.new(
            'type' => 'tuple',
            'values' => [
              Coinbase::Client::SolidityValue.new({
                                                    'type' => 'uint256',
                                                    'name' => 'a',
                                                    'value' => '1'
                                                  }),
              Coinbase::Client::SolidityValue.new({
                                                    'type' => 'address',
                                                    'name' => 'b',
                                                    'value' => address
                                                  }),
              Coinbase::Client::SolidityValue.new({
                                                    'type' => 'bool',
                                                    'name' => 'c',
                                                    'value' => 'true'
                                                  })
            ]
          )
        )
      end

      it 'returns the parsed tuple with mixed types' do
        expect(result).to eq({
                               'a' => 1,
                               'b' => address,
                               'c' => true
                             })
      end
    end

    describe 'nested struct type' do
      let(:method_name_for_context) { 'pureNestedStruct' }

      before do
        allow(smart_contracts_api).to receive(:read_contract).and_return(
          Coinbase::Client::SolidityValue.new(
            'type' => 'tuple',
            'values' => [
              Coinbase::Client::SolidityValue.new(
                'type' => 'uint256',
                'name' => 'a',
                'value' => '123'
              ),
              Coinbase::Client::SolidityValue.new(
                'type' => 'tuple',
                'name' => 'nestedFields',
                'values' => [
                  Coinbase::Client::SolidityValue.new(
                    'type' => 'tuple',
                    'name' => 'nestedArray',
                    'values' => [
                      Coinbase::Client::SolidityValue.new(
                        'type' => 'array',
                        'name' => 'a',
                        'values' => [
                          Coinbase::Client::SolidityValue.new(
                            'type' => 'uint256',
                            'value' => '1'
                          ),
                          Coinbase::Client::SolidityValue.new(
                            'type' => 'uint256',
                            'value' => '2'
                          ),
                          Coinbase::Client::SolidityValue.new(
                            'type' => 'uint256',
                            'value' => '3'
                          )
                        ]
                      )
                    ]
                  ),
                  Coinbase::Client::SolidityValue.new(
                    'type' => 'uint256',
                    'name' => 'a',
                    'value' => '456'
                  )
                ]
              )
            ]
          )
        )
      end

      it 'returns the parsed nested struct value with proper type conversion' do
        expected_result = {
          'a' => 123,
          'nestedFields' => {
            'nestedArray' => {
              'a' => [1, 2, 3]
            },
            'a' => 456
          }
        }
        expect(result).to eq(expected_result)
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
