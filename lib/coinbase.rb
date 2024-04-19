# frozen_string_literal: true

require_relative 'coinbase/address'
require_relative 'coinbase/asset'
require_relative 'coinbase/balance_map'
require_relative 'coinbase/constants'
require_relative 'coinbase/network'
require_relative 'coinbase/transfer'
require_relative 'coinbase/wallet'

# The Coinbase SDK.
module Coinbase
  @base_sepolia_rpc_url = 'https://sepolia.base.org'

  # Returns the Base Sepolia RPC URL.
  # @return [String] the Base Sepolia RPC URL
  def self.base_sepolia_rpc_url
    @base_sepolia_rpc_url
  end

  # Sets the Base Sepolia RPC URL.
  # @param value [String] the Base Sepolia RPC URL
  def self.base_sepolia_rpc_url=(value)
    @base_sepolia_rpc_url = value
  end
end
