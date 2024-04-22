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

  # Returns the API key name.
  # @return [String] the API key name
  def self.api_key_name
    raise 'API key name is not set' unless @api_key_name

    @api_key_name
  end

  # Sets the API key name.
  # @param value [String] the API key name
  def self.api_key_name=(value)
    @api_key_name = value
  end

  # Returns the API key's private key.
  # @return [String] the API key's private key
  def self.api_key_private_key
    raise 'API key private key is not set' unless @api_key_private_key

    @api_key_private_key
  end

  # Sets the API key's private key.
  # @param value [String] the API key's private key
  def self.api_key_private_key=(value)
    @api_key_private_key = value
  end
end
