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
require_relative 'coinbase/user'
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
    @api_client ||= Coinbase::Client::ApiClient.new(Middleware.config)
    @users_api ||= Coinbase::Client::UsersApi.new(@api_client)
    @wallets_api ||= Coinbase::Client::WalletsApi.new(@api_client)
    @addresses_api ||= Coinbase::Client::AddressesApi.new(@api_client)
    @transfers_api ||= Coinbase::Client::TransfersApi.new(@api_client)
    @user_model ||= @users_api.get_current_user
    @default_user ||= Coinbase::User.new(@user_model, @wallets_api, @addresses_api, @transfers_api)
  end

  # Converts a string to a symbol, replacing hyphens with underscores.
  # @param string [String] the string to convert
  # @return [Symbol] the converted symbol
  def self.to_sym(value)
    value.to_s.gsub('-', '_').to_sym
  end

  # Converts a Coinbase::Client::AddressBalanceList to a BalanceMap.
  # @param address_balance_list [Coinbase::Client::AddressBalanceList] The AddressBalanceList to convert
  # @return [BalanceMap] The converted BalanceMap
  def self.to_balance_map(address_balance_list)
    balances = {}

    address_balance_list.data.each do |balance|
      asset_id = Coinbase.to_sym(balance.asset.asset_id.downcase)
      amount = if asset_id == :eth
                 BigDecimal(balance.amount) / BigDecimal(Coinbase::WEI_PER_ETHER)
               else
                 BigDecimal(balance.amount)
               end
      balances[asset_id] = amount
    end

    BalanceMap.new(balances)
  end
end
