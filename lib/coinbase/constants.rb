# frozen_string_literal: true

require_relative 'asset'
require_relative 'network'

module Coinbase
  # The Base Sepolia Network.
  BASE_SEPOLIA = Network.new(
    network_id: :base_sepolia,
    display_name: 'Base Sepolia',
    protocol_family: :evm,
    is_testnet: true,
    native_asset_id: :eth,
    chain_id: 84_532
  )

  BASE_MAINNET = Network.new(
    network_id: :base_mainnet,
    display_name: 'Base Mainnet',
    protocol_family: :evm,
    is_testnet: false,
    native_asset_id: :eth,
    chain_id: 8453
  )

  ETHEREUM_HOLESKY = Network.new(
    network_id: :ethereum_holesky,
    display_name: 'Ethereum Holesky',
    protocol_family: :evm,
    is_testnet: true,
    native_asset_id: :eth,
    chain_id: 17_000
  )

  ETHEREUM_MAINNET = Network.new(
    network_id: :ethereum_mainnet,
    display_name: 'Ethereum Mainnet',
    protocol_family: :evm,
    is_testnet: false,
    native_asset_id: :eth,
    chain_id: 1
  )

  # The number of decimal places in Gwei.
  GWEI_DECIMALS = 9

  # The default page limit for paginated API requests.
  DEFAULT_PAGE_LIMIT = 100
end
