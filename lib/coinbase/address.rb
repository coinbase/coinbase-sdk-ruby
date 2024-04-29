# frozen_string_literal: true

require_relative 'balance_map'
require_relative 'constants'
require_relative 'wallet'
require 'bigdecimal'
require 'eth'
require 'jimson'

module Coinbase
  # A representation of a blockchain Address, which is a user-controlled account on a Network. Addresses are used to
  # send and receive Assets, and should be created using Wallet#create_address. Addresses require an
  # Eth::Key to sign transaction data.
  class Address
    # Returns a new Address object. Do not use this method directly. Instead, use Wallet#create_address.
    # @param model [Coinbase::Client::Address] The underlying Address object
    # @param addresses_api [Coinbase::Client::AddressesApi] The Addresses API object
    # @param key [Eth::Key] The key backing the Address
    def initialize(model, addresses_api, key)
      @model = model
      @addresses_api = addresses_api
      @key = key
    end

    # Returns the Network ID of the Address.
    # @return [Symbol] The Network ID
    def network_id
      Coinbase.to_sym(@model.network_id)
    end

    # Returns the Wallet ID of the Address.
    # @return [String] The Wallet ID
    def wallet_id
      @model.wallet_id
    end

    # Returns the Address ID.
    # @return [String] The Address ID
    def address_id
      @model.address_id
    end

    # Returns the balances of the Address. Currently only ETH balances are supported.
    # @return [BalanceMap] The balances of the Address, keyed by asset ID. Ether balances are denominated
    #  in ETH.
    def list_balances
      response = @addresses_api.list_address_balances(wallet_id, address_id)
      Coinbase.to_balance_map(response)
    end

    # Returns the balance of the provided Asset. Currently only ETH is supported.
    # @param asset_id [Symbol] The Asset to retrieve the balance for
    # @return [BigDecimal] The balance of the Asset
    def get_balance(asset_id)
      normalized_asset_id = if %i[wei gwei].include?(asset_id)
                              :eth
                            else
                              asset_id
                            end

      response = @addresses_api.get_address_balance(wallet_id, address_id, normalized_asset_id.to_s)

      return BigDecimal('0') if response.nil?

      amount = BigDecimal(response.amount)

      case asset_id
      when :eth
        amount / BigDecimal(Coinbase::WEI_PER_ETHER.to_s)
      when :gwei
        amount / BigDecimal(Coinbase::GWEI_PER_ETHER.to_s)
      else
        amount
      end
    end

    # Transfers the given amount of the given Asset to the given address. Only same-Network Transfers are supported.
    # @param amount [Integer, Float, BigDecimal] The amount of the Asset to send.
    # @param asset_id [Symbol] The ID of the Asset to send. For Ether, :eth, :gwei, and :wei are supported.
    # @param destination [Wallet | Address | String] The destination of the transfer. If a Wallet, sends to the Wallet's
    #  default address. If a String, interprets it as the address ID.
    # @return [String] The hash of the Transfer transaction.
    def transfer(amount, asset_id, destination)
      # TODO: Handle multiple currencies.
      raise ArgumentError, "Unsupported asset: #{asset_id}" unless Coinbase::SUPPORTED_ASSET_IDS[asset_id]

      if destination.is_a?(Wallet)
        raise ArgumentError, 'Transfer must be on the same Network' if destination.network_id != network_id

        destination = destination.default_address.address_id
      elsif destination.is_a?(Address)
        raise ArgumentError, 'Transfer must be on the same Network' if destination.network_id != network_id

        destination = destination.address_id
      end

      current_balance = get_balance(asset_id)
      if current_balance < amount
        raise ArgumentError, "Insufficient funds: #{amount} requested, but only #{current_balance} available"
      end

      transfer = Coinbase::Transfer.new(network_id, wallet_id, address_id, amount, asset_id, destination)

      transaction = transfer.transaction
      transaction.sign(@key)
      client.eth_sendRawTransaction("0x#{transaction.hex}")

      transfer
    end

    # Returns the address as a string.
    # @return [String] The address
    def to_s
      address_id
    end

    private

    # Normalizes the amount of ETH to send based on the asset ID.
    # @param amount [Integer, Float, BigDecimal] The amount to normalize
    # @param asset_id [Symbol] The ID of the Asset being transferred
    # @return [BigDecimal] The normalized amount in units of ETH
    def normalize_eth_amount(amount, asset_id)
      case asset_id
      when :eth
        amount.is_a?(BigDecimal) ? amount : BigDecimal(amount.to_s)
      when :gwei
        BigDecimal(amount / Coinbase::GWEI_PER_ETHER)
      when :wei
        BigDecimal(amount / Coinbase::WEI_PER_ETHER)
      else
        raise ArgumentError, "Unsupported asset: #{asset_id}"
      end
    end

    def client
      @client ||= Coinbase.configuration.base_sepolia_client
    end
  end
end
