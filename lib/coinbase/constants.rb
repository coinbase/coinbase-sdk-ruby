# frozen_string_literal: true

require_relative 'asset'
require_relative 'network'

module Coinbase
  # The Assets supported on Base Sepolia by the Coinbase SDK.
  ETH = Asset.new(network_id: :base_sepolia, asset_id: :eth, display_name: 'Ether')
  USDC = Asset.new(network_id: :base_sepolia, asset_id: :usdc, display_name: 'USD Coin',
                   address_id: '0x036CbD53842c5426634e7929541eC2318f3dCF7e')

  # The Base Sepolia Network.
  BASE_SEPOLIA = Network.new(
    network_id: :base_sepolia,
    display_name: 'Base Sepolia',
    protocol_family: :evm,
    is_testnet: true,
    assets: [ETH, USDC],
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
