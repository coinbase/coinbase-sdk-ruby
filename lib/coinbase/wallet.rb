# frozen_string_literal: true

require 'bigdecimal'
require 'eth'
require 'money-tree'
require 'securerandom'

module Coinbase
  # A crypto wallet.
  class Wallet
    # Returns a new Wallet object.
    def initialize
      @wallet_id = SecureRandom.uuid
      @master = MoneyTree::Master.new
      # TODO: Make Network an argument to the constructor.
      @network_id = :base_sepolia
      @addresses = []

      # TODO: Adjust derivation path prefix based on network protocol.
      @address_path_prefix = "m/44'/60'/0'/0"
      @address_index = 0

      # TODO: Don't hardcode the JSON RPC URL.
      @client = Eth::Client.create(ENV.fetch('BASE_SEPOLIA_RPC_URL', nil))

      create_address
    end

    # Creates a new Address in the Wallet.
    # @return [Address] The new Address
    def create_address
      # TODO: Register with server.
      path = "#{@address_path_prefix}/#{@address_index}"
      private_key = @master.node_for_path(path).private_key.to_hex
      key = Eth::Key.new(priv: private_key)
      address = Address.new(@network_id, key.address.address, @wallet_id, key)
      @addresses << address
      @address_index += 1
      address
    end

    # Returns the default address of the Wallet.
    # @return [Address] The default address
    def default_address
      @addresses.first
    end

    # Returns the Address with the given ID.
    # @param address_id [String] The ID of the Address to retrieve
    # @return [Address] The Address
    def get_address(address_id)
      @addresses.find { |address| address.address_id == address_id }
    end

    # Returns the list of addresses in the Wallet.
    # @return [Array<Address>] The list of addresses
    def list_addresses
      # TODO: Register with server.
      @addresses
    end

    # Returns the list of balances of this Wallet. Balances are aggregated across all Addresses in the Wallet.
    # @return [Map<Symbol, Integer>] The list of balances
    def list_balances
      balance_map = {}

      @addresses.each do |address|
        address.list_balances.each do |asset_id, balance|
          balance_map[asset_id] ||= 0
          current_balance = BigDecimal(balance_map[asset_id])
          new_balance = balance + current_balance
          balance_map[asset_id] = new_balance
        end
      end

      balance_map
    end

    # Returns the balance of the provided Asset. Balances are aggregated across all Addresses in the Wallet.
    # @param asset_id [Symbol] The Asset to retrieve the balance for
    # @return [Integer] The balance of the Asset
    def get_balance(asset_id)
      list_balances[asset_id]
    end

    # Transfers the given amount of the given Asset to the given address. Only same-Network Transfers are supported.
    # Currently only the default_address is used to source the Transfer.
    # @param amount [Integer, Float, BigDecimal] The amount of the Asset to send. Integers are interpreted as
    #  the smallest denomination of the Asset (e.g. Wei for Ether). Floats and BigDecimals are interpreted as the Asset
    #  itself (e.g. Ether).
    # @param asset_id [Symbol] The ID of the Asset to send
    # @param to_address_id [String] The ID of the address to send the Asset to
    # @return [String] The hash of the Transfer transaction.
    def transfer(amount, asset_id, to_address_id)
      default_address.transfer(amount, asset_id, to_address_id)
    end
  end
end
