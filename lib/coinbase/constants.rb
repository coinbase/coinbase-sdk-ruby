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

  # The number of decimal places in Gwei.
  GWEI_DECIMALS = 9

  # The default page limit for paginated API requests.
  DEFAULT_PAGE_LIMIT = 100
end
