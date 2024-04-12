# frozen_string_literal: true

require 'eth'

module Coinbase
  # A blockchain address.
  class Address
    attr_reader :address_id

    # Returns a new Address object.
    # @param network_id [Symbol] The Network ID
    # @param address_id [String] The Address ID
    # @param wallet_id [String] The Wallet ID
    # @return [Address] The new Address object
    def initialize(network_id, address_id, wallet_id)
      @network_id = network_id
      @address_id = address_id
      @wallet_id = wallet_id

      # TODO: Don't hardcode the JSON RPC URL.
      @client = Eth::Client.create(ENV.fetch('BASE_SEPOLIA_RPC_URL', nil))
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
    # @param to_address_id [String] The ID of the address to send the Asset to
    # @param asset_id [Symbol] The ID of the Asset to send
    # @param amount [Integer, Float, BigDecimal, String] The amount of the Asset to send. Integers are interpreted as
    #  the smallest denomination of the Asset (e.g. Wei for Ether). Floats and BigDecimals are interpreted as the Asset
    #  itself (e.g. Ether). Strings are reduced to Integers or BigDecimals.
    # @return [Transfer] The Transfer object representing the transfer
    def transfer(to_address_id, asset_id, amount)
    end

    # Returns the address as a string.
    # @return [String] The address
    def to_s
      @address_id
    end
  end
end
