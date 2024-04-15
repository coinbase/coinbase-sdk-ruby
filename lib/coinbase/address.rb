# frozen_string_literal: true

require_relative 'constants'
require 'eth'
require 'jimson'

module Coinbase
  # A representation of a blockchain Address, which is a user-controlled account on a Network. Addresses are used to
  # send and receive Assets, and should be created using {link:Wallet#create_address}. Addresses require a
  # {link:Eth::Key} to sign transaction data.
  class Address
    attr_reader :network_id, :address_id, :wallet_id

    # Returns a new Address object.
    # @param network_id [Symbol] The ID of the Network on which the Address exists
    # @param address_id [String] The ID of the Address. On EVM Networks, for example, this is a hash of the public key.
    # @param wallet_id [String] The ID of the Wallet to which the Address belongs
    # @param key [Eth::Key] The key backing the Address
    # @param client [Jimson::Client] (Optional) The JSON RPC client to use for interacting with the Network
    def initialize(network_id, address_id, wallet_id, key,
                   client: Jimson::Client.new(ENV.fetch('BASE_SEPOLIA_RPC_URL', nil)))
      # TODO: Don't require key.
      @network_id = network_id
      @address_id = address_id
      @wallet_id = wallet_id
      @key = key
      @client = client
    end

    # Returns the balances of the Address. Currently only ETH balances are supported.
    # @return [Map<Symbol, Integer>] The balances of the Address, keyed by asset ID. Ether balances are denominated in
    #   Wei.
    def list_balances
      # TODO: Handle multiple currencies.
      eth_balance_in_wei = @client.eth_getBalance(@address_id, 'latest').to_i(16)

      { eth: eth_balance_in_wei }
    end

    # Returns the balance of the provided Asset. Currently only ETH is supported.
    # @param asset_id [Symbol] The Asset to retrieve the balance for
    # @return [Integer] The balance of the Asset
    def get_balance(asset_id)
      list_balances[asset_id] || 0
    end

    # Transfers the given amount of the given Asset to the given address. Only same-Network Transfers are supported.
    # @param amount [Integer, Float, BigDecimal] The amount of the Asset to send. Integers are interpreted as
    #  the smallest denomination of the Asset (e.g. Wei for Ether). Floats and BigDecimals are interpreted as the Asset
    #  itself (e.g. Ether).
    # @param asset_id [Symbol] The ID of the Asset to send
    # @param destination [Wallet | Address | String] The destination of the transfer. If a Wallet, sends to the Wallet's
    #  default address. If a String, interprets it as the address ID.
    # @return [String] The hash of the Transfer transaction.
    def transfer(amount, asset_id, destination)
      # TODO: Handle multiple currencies.
      raise ArgumentError, "Unsupported asset: #{asset_id}" if asset_id != :eth

      if destination.is_a?(Wallet)
        raise ArgumentError, 'Transfer must be on the same Network' if destination.network_id != @network_id

        destination = destination.default_address.address_id
      elsif destination.is_a?(Address)
        raise ArgumentError, 'Transfer must be on the same Network' if destination.network_id != @network_id

        destination = destination.address_id
      end

      current_balance = get_balance(:eth)
      if current_balance < amount
        raise ArgumentError, "Insufficient funds: #{amount} ETH requested, but only #{current_balance} ETH available"
      end

      transfer = Coinbase::Transfer.new(@network_id, @wallet_id, @address_id, amount, asset_id, destination,
                                        client: @client)

      transaction = transfer.transaction
      transaction.sign(@key)
      @client.eth_sendRawTransaction("0x#{transaction.hex}")

      transfer
    end

    # Returns the address as a string.
    # @return [String] The address
    def to_s
      @address_id
    end
  end
end
