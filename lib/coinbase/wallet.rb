# frozen_string_literal: true

require 'money-tree'

module Coinbase
  # A crypto wallet.
  class Wallet
    def initialize
      @master = MoneyTree::Master.new
      @network_id = :bitcoin_testnet
      @addresses = []

      # TODO: Adjust derivation path prefix based on network protocol.
      @address_path_prefix = "m/44'/0'/0'/0"
      @address_index = 0

      create_address
    end

    # Creates a new Address in the Wallet.
    # @return [String] The new Address
    def create_address
      # TODO: Register with server.
      path = "#{@address_path_prefix}/#{@address_index}"
      address = @master.node_for_path(path).to_address
      @addresses << address
      @address_index += 1
      address
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
      # TODO: Register with server.
      @addresses
    end
  end
end
