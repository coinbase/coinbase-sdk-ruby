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
  class InvalidConfiguration < StandardError; end

  def self.configuration
    @configuration ||= Configuration.new
  end

  def self.configure
    yield(configuration)

    raise InvalidConfiguration, 'API key private key is not set' unless configuration.api_key_private_key
    raise InvalidConfiguration, 'API key name is not set' unless configuration.api_key_name
  end

  # Configuration object for the Coinbase SDK
  class Configuration
    attr_reader :base_sepolia_rpc_url, :base_sepolia_client
    attr_accessor :api_url, :api_key_name, :api_key_private_key

    def initialize
      @base_sepolia_rpc_url = 'https://sepolia.base.org'
      @base_sepolia_client = Jimson::Client.new(@base_sepolia_rpc_url)
      @api_url = 'https://api.cdp.coinbase.com'
    end

    def base_sepolia_rpc_url=(new_base_sepolia_rpc_url)
      @base_sepolia_rpc_url = new_base_sepolia_rpc_url
      @base_sepolia_client = Jimson::Client.new(@base_sepolia_rpc_url)
    end

    def api_client
      @api_client ||= Coinbase::Client::ApiClient.new(Middleware.config)
    end
  end

  # Returns the default user.
  # @return [Coinbase::User] the default user
  def self.default_user
    @default_user ||= load_default_user
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
               elsif asset_id == :usdc
                 BigDecimal(balance.amount) / BigDecimal(Coinbase::ATOMIC_UNITS_PER_USDC)
               else
                 BigDecimal(balance.amount)
               end
      balances[asset_id] = amount
    end

    BalanceMap.new(balances)
  end

  def self.load_default_user
    users_api = Coinbase::Client::UsersApi.new(configuration.api_client)
    user_model = users_api.get_current_user
    Coinbase::User.new(user_model)
  end
end
