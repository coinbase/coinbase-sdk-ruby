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
    # @return [Hash<Symbol, BigDecimal>] The balances
    def list_balances
      # TODO: Handle multiple currencies.
      eth_balance = @client.get_balance(@address_id)

      { eth: BigDecimal(eth_balance) }
    end

    # Returns the address as a string.
    # @return [String] The address
    def to_s
      @address_id
    end
  end
end
