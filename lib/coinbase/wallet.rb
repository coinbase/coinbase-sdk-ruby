# frozen_string_literal: true

require 'money-tree'

module Coinbase
  # A crypto wallet.
  class Wallet
    def initialize
      @master = MoneyTree::Master.new
      @network_id = :bitcoin_testnet
      @addresses = []

      # TODO: Adjust derivation path based on network protocol.
      first_address = @master.node_for_path('m/44h/0h/0h/0/0')

      # TODO: Change to a list of Address objects.
      # TODO: Register with server.
      @addresses << first_address.to_address
    end

    # Returns the default address of the Wallet.
    # @return [String] The default address
    def default_address
      @addresses.first
    end

    # Returns the Address with the given ID.
    # @param address_id [String] The ID of the Address to retrieve
    # @return [String] The Address
    def get_address(address_id)
      @addresses.find { |address| address == address_id }
    end

    # Returns the list of addresses in the Wallet.
    # @return [Array<String>] The list of addresses
    def list_addresses
      @addresses
    end
  end
end
