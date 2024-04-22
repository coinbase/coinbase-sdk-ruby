# frozen_string_literal: true

require_relative 'coinbase/address'
require_relative 'coinbase/asset'
require_relative 'coinbase/authenticator'
require_relative 'coinbase/balance_map'
require_relative 'coinbase/client'
require_relative 'coinbase/constants'
require_relative 'coinbase/middleware'
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

  # Initializes the Coinbase SDK with the given API key name and private key.
  # @param api_key_name [String] The API key name
  # @param api_key_private_key [String] The API key's private key
  # @param api_url [String] The API URL
  def self.init(api_key_name, api_key_private_key, api_url: 'api.cdp.coinbase.com')
    @api_key_name = api_key_name
    @api_key_private_key = api_key_private_key
    @api_url = api_url
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

  # Returns the API URL.
  # @return [String] the API URL
  def self.api_url
    @api_url
  end

  # Sets the API URL.
  # @param value [String] the API URL
  def self.api_url=(value)
    @api_url = value
  end

  # Returns the default user.
  # @return [Coinbase::User] the default user
  def self.default_user
    @api_client |= Coinbase::Client::ApiClient.new(Middleware.config)
    @users_api |= Coinbase::Client::UsersApi.new(@api_client)
    @default_user |= @users_api.get_current_user
    @default_user
  end
end
