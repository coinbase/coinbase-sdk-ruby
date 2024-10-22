# frozen_string_literal: true

# Omitted all the configuration, private keys, etc.

# ABI definition
ABI = [
  {
    type: 'function',
    name: 'pureInt16',
    inputs: [],
    outputs: [{ name: '', type: 'int16' }],
    stateMutability: 'pure'
  },
  {
    type: 'function',
    name: 'pureUint16',
    inputs: [],
    outputs: [{ name: '', type: 'uint16' }],
    stateMutability: 'pure'
  },
  {
    type: 'function',
    name: 'pureUint256',
    inputs: [],
    outputs: [{ name: '', type: 'uint256' }],
    stateMutability: 'pure'
  },
  {
    type: 'function',
    name: 'pureInt256',
    inputs: [],
    outputs: [{ name: '', type: 'int256' }],
    stateMutability: 'pure'
  },
  {
    type: 'function',
    name: 'pureUint128',
    inputs: [],
    outputs: [{ name: '', type: 'uint128' }],
    stateMutability: 'pure'
  },
  {
    type: 'function',
    name: 'pureUint64',
    inputs: [],
    outputs: [{ name: '', type: 'uint64' }],
    stateMutability: 'pure'
  },
  {
    type: 'function',
    name: 'pureUint32',
    inputs: [],
    outputs: [{ name: '', type: 'uint32' }],
    stateMutability: 'pure'
  },
  {
    type: 'function',
    name: 'pureBool',
    inputs: [],
    outputs: [{ name: '', type: 'bool' }],
    stateMutability: 'pure'
  },
  {
    type: 'function',
    name: 'pureAddress',
    inputs: [],
    outputs: [{ name: '', type: 'address' }],
    stateMutability: 'pure'
  },
  {
    type: 'function',
    name: 'exampleFunction',
    inputs: [{ name: 'z', type: 'uint256' }],
    outputs: [{ name: '', type: 'bool' }],
    stateMutability: 'pure'
  },
  {
    type: 'function',
    name: 'pureArray',
    inputs: [],
    outputs: [{ name: '', type: 'uint256[]' }],
    stateMutability: 'pure'
  },
  {
    type: 'function',
    name: 'pureBytes',
    inputs: [],
    outputs: [{ name: '', type: 'bytes' }],
    stateMutability: 'pure'
  },
  {
    type: 'function',
    name: 'pureBytes1',
    inputs: [],
    outputs: [{ name: '', type: 'bytes1' }],
    stateMutability: 'pure'
  },
  {
    type: 'function',
    name: 'pureNestedStruct',
    inputs: [],
    outputs: [
      {
        name: '',
        type: 'tuple',
        components: [
          { name: 'a', type: 'uint256' },
          {
            name: 'nestedFields',
            type: 'tuple',
            components: [
              {
                name: 'nestedArray',
                type: 'tuple',
                components: [{ name: 'a', type: 'uint256[]' }]
              },
              { name: 'a', type: 'uint256' }
            ]
          }
        ]
      }
    ],
    stateMutability: 'pure'
  },
  {
    inputs: [{ name: 'x', type: 'uint256' }, { name: 'y', type: 'uint256' }],
    name: 'overload',
    outputs: [{ name: '', type: 'uint256[]' }],
    stateMutability: 'pure',
    type: 'function'
  },
  {
    inputs: [],
    name: 'overload',
    outputs: [{ name: '', type: 'uint256' }],
    stateMutability: 'pure',
    type: 'function'
  },
  {
    inputs: [{ name: 'x', type: 'address' }],
    name: 'overload',
    outputs: [{ name: '', type: 'uint256' }],
    stateMutability: 'pure',
    type: 'function'
  }
].freeze

CONTRACT_ADDRESS = '0x0B54409D1B1dd1438eDF7729CDAea3E331Ae12ED'
NETWORK_ID = :base_sepolia

def test_read_contract
  # Test pureInt16
  int16 = Coinbase::SmartContract.read(
    network_id: NETWORK_ID,
    contract_address: CONTRACT_ADDRESS,
    method: 'pureInt16',
    abi: ABI
  )
  puts "pureInt16: #{int16}"

  # Test pureUint16
  uint16 = Coinbase::SmartContract.read(
    network_id: NETWORK_ID,
    contract_address: CONTRACT_ADDRESS,
    method: 'pureUint16',
    abi: ABI
  )
  puts "pureUint16: #{uint16}"

  # Test pureUint256
  uint256 = Coinbase::SmartContract.read(
    network_id: NETWORK_ID,
    contract_address: CONTRACT_ADDRESS,
    method: 'pureUint256',
    abi: ABI
  )
  puts "pureUint256: #{uint256}"

  # Test pureInt256
  int256 = Coinbase::SmartContract.read(
    network_id: NETWORK_ID,
    contract_address: CONTRACT_ADDRESS,
    method: 'pureInt256',
    abi: ABI
  )
  puts "pureInt256: #{int256}"

  # Test pureUint128
  uint128 = Coinbase::SmartContract.read(
    network_id: NETWORK_ID,
    contract_address: CONTRACT_ADDRESS,
    method: 'pureUint128',
    abi: ABI
  )
  puts "pureUint128: #{uint128}"

  # Test pureUint64
  uint64 = Coinbase::SmartContract.read(
    network_id: NETWORK_ID,
    contract_address: CONTRACT_ADDRESS,
    method: 'pureUint64',
    abi: ABI
  )
  puts "pureUint64: #{uint64}"

  # Test pureUint32
  uint32 = Coinbase::SmartContract.read(
    network_id: NETWORK_ID,
    contract_address: CONTRACT_ADDRESS,
    method: 'pureUint32',
    abi: ABI
  )
  puts "pureUint32: #{uint32}"

  # Test pureBool
  bool_value = Coinbase::SmartContract.read(
    network_id: NETWORK_ID,
    contract_address: CONTRACT_ADDRESS,
    method: 'pureBool',
    abi: ABI
  )
  puts "pureBool: #{bool_value}"

  # Test pureAddress
  address = Coinbase::SmartContract.read(
    network_id: NETWORK_ID,
    contract_address: CONTRACT_ADDRESS,
    method: 'pureAddress',
    abi: ABI
  )
  puts "pureAddress: #{address}"

  # Test exampleFunction
  example_bool = Coinbase::SmartContract.read(
    network_id: NETWORK_ID,
    contract_address: CONTRACT_ADDRESS,
    method: 'exampleFunction',
    abi: ABI,
    args: { z: '1' }
  )
  puts "exampleFunction: #{example_bool}"

  # Test pureArray
  array = Coinbase::SmartContract.read(
    network_id: NETWORK_ID,
    contract_address: CONTRACT_ADDRESS,
    method: 'pureArray',
    abi: ABI
  )
  puts "pureArray: #{array}"

  # Test pureBytes
  pure_bytes = Coinbase::SmartContract.read(
    network_id: NETWORK_ID,
    contract_address: CONTRACT_ADDRESS,
    method: 'pureBytes',
    abi: ABI
  )
  puts "pureBytes: #{pure_bytes}"

  # Test pureBytes1
  pure_bytes1 = Coinbase::SmartContract.read(
    network_id: NETWORK_ID,
    contract_address: CONTRACT_ADDRESS,
    method: 'pureBytes1',
    abi: ABI
  )
  puts "pureBytes1: #{pure_bytes1}"

  # Test pureNestedStruct
  nested_struct = Coinbase::SmartContract.read(
    network_id: NETWORK_ID,
    contract_address: CONTRACT_ADDRESS,
    method: 'pureNestedStruct',
    abi: ABI
  )
  puts "pureNestedStruct: #{nested_struct.to_json}"

  # Test overload (with two uint256 arguments)
  overload1 = Coinbase::SmartContract.read(
    network_id: NETWORK_ID,
    contract_address: CONTRACT_ADDRESS,
    method: 'overload',
    abi: ABI,
    args: { x: '1', y: '2' }
  )
  puts "overload (x: 1, y: 2): #{overload1}"

  # Test overload (no arguments)
  overload2 = Coinbase::SmartContract.read(
    network_id: NETWORK_ID,
    contract_address: CONTRACT_ADDRESS,
    method: 'overload',
    abi: ABI
  )
  puts "overload (no args): #{overload2}"

  # Test overload (with address argument)
  overload3 = Coinbase::SmartContract.read(
    network_id: NETWORK_ID,
    contract_address: CONTRACT_ADDRESS,
    method: 'overload',
    abi: ABI,
    args: { x: '0x0B54409D1B1dd1438eDF7729CDAea3E331Ae12ED' }
  )
  puts "overload (address arg): #{overload3}"
end

# Run the tests
test_read_contract
