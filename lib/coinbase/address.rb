# frozen_string_literal: true

require_relative 'constants'
require 'eth'

module Coinbase
  # A blockchain address.
  class Address
    attr_reader :address_id

    # Returns a new Address object.
    # @param network_id [Symbol] The Network ID
    # @param address_id [String] The Address ID
    # @param wallet_id [String] The Wallet ID
    # @param key [Eth::Key] The Key backing the Address.
    # @return [Address] The new Address object
    def initialize(network_id, address_id, wallet_id, key)
      # TODO: Don't require key.
      @network_id = network_id
      @address_id = address_id
      @wallet_id = wallet_id
      @key = key

      # TODO: Don't hardcode the JSON RPC URL.
      @client = Eth::Client.create(ENV.fetch('BASE_SEPOLIA_RPC_URL', nil))

      # TODO: Make gas estimation dynamic.
      @client.max_fee_per_gas = 2 * WEI_PER_GWEI
    end

    # Returns the balances of the Address.
    # @return [Map<Symbol, Integer>] The balances of the Address, keyed by asset ID. Ether balances are denominated in
    #   Wei.
    def list_balances
      # TODO: Handle multiple currencies.
      eth_balance_in_wei = @client.get_balance(@address_id)

      { eth: eth_balance_in_wei }
    end

    # Returns the balance of the provided Asset.
    # @param asset_id [Symbol] The Asset to retrieve the balance for
    # @return [Integer] The balance of the Asset
    def get_balance(asset_id)
      list_balances[asset_id]
    end

    # Transfers the given amount of the given Asset to the given address. Only same-Network Transfers are supported.
    # @param amount [Integer, Float, BigDecimal] The amount of the Asset to send. Integers are interpreted as
    #  the smallest denomination of the Asset (e.g. Wei for Ether). Floats and BigDecimals are interpreted as the Asset
    #  itself (e.g. Ether).
    # @param asset_id [Symbol] The ID of the Asset to send
    # @param to_address_id [String] The ID of the address to send the Asset to
    # @return [String] The hash of the Transfer transaction.
    def transfer(amount, asset_id, to_address_id)
      # TODO: Handle multiple currencies.
      raise ArgumentError, "Unsupported asset: #{asset_id}" if asset_id != :eth

      Eth::Address.new(to_address_id)
      normalized_amount = normalize_eth_amount(amount)
      @client.transfer(to_address_id, normalized_amount, sender_key: @key)
    end

    # Returns the address as a string.
    # @return [String] The address
    def to_s
      @address_id
    end

    private

    # Normalizes the given Ether amount into an Integer.
    # @param amount [Integer, Float, BigDecimal] The amount to normalize
    # @return [Integer] The normalized amount
    def normalize_eth_amount(amount)
      case amount
      when Integer
        amount
      when Float, BigDecimal
        amount.to_i * WEI_PER_ETHER
      else
        raise ArgumentError, "Invalid amount: #{amount}"
      end
    end
  end
end
