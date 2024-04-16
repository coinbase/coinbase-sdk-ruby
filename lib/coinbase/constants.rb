# frozen_string_literal: true

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

  # The amount of Wei per Ether.
  WEI_PER_ETHER = 1_000_000_000_000_000_000

  # The amount of Wei per Gwei.
  WEI_PER_GWEI = 1_000_000_000

  # The amount of Gwei per Ether.
  GWEI_PER_ETHER = 1_000_000_000

  # A map of supported Asset IDs.
  SUPPORTED_ASSET_IDS = {
    eth: true, # Ether, the native asset of most EVM networks.
    gwei: true, # A medium denomination of Ether, typically used in gas prices.
    wei: true # The smallest denomination of Ether.
  }.freeze
end
