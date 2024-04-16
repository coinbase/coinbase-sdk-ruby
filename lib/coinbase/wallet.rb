# frozen_string_literal: true

require 'jimson'
require 'money-tree'
require 'securerandom'

module Coinbase
  # A representation of a Wallet. Wallets come with a single default Address, but can expand to have a set of Addresses,
  # each of which can hold a balance of one or more Assets. Wallets can create new Addresses, list their addresses,
  # list their balances, and transfer Assets to other Addresses.
  class Wallet
    attr_reader :wallet_id, :network_id

    # Returns a new Wallet object.
    # @param seed [Integer] (Optional) The seed to use for the Wallet. Expects a 32-byte hexadecimal. If not provided,
    #   a new seed will be generated.
    # @param client [Jimson::Client] (Optional) The JSON RPC client to use for interacting with the Network
    def initialize(seed: nil, client: Jimson::Client.new(ENV.fetch('BASE_SEPOLIA_RPC_URL', nil)))
      raise ArgumentError, 'Seed must be 32 bytes' if !seed.nil? && seed.length != 64

      @master = seed.nil? ? MoneyTree::Master.new : MoneyTree::Master.new(seed_hex: seed)

      @wallet_id = SecureRandom.uuid
      # TODO: Make Network an argument to the constructor.
      @network_id = :base_sepolia
      @addresses = []

      # TODO: Adjust derivation path prefix based on network protocol.
      @address_path_prefix = "m/44'/60'/0'/0"
      @address_index = 0

      @client = client

      create_address
    end

    # Creates a new Address in the Wallet.
    # @return [Address] The new Address
    def create_address
      # TODO: Register with server.
      path = "#{@address_path_prefix}/#{@address_index}"
      private_key = @master.node_for_path(path).private_key.to_hex
      key = Eth::Key.new(priv: private_key)
      address = Address.new(@network_id, key.address.address, @wallet_id, key, client: @client)
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

    # Returns the list of Addresses in the Wallet.
    # @return [Array<Address>] The list of Addresses
    def list_addresses
      # TODO: Register with server.
      @addresses
    end

    # Returns the list of balances of this Wallet. Balances are aggregated across all Addresses in the Wallet.
    # @return [BalanceMap] The list of balances. The key is the Asset ID, and the value is the balance.
    def list_balances
      balance_map = BalanceMap.new

      @addresses.each do |address|
        address.list_balances.each do |asset_id, balance|
          balance_map[asset_id] ||= BigDecimal(0)
          current_balance = balance_map[asset_id]
          new_balance = balance + current_balance
          balance_map[asset_id] = new_balance
        end
      end

      balance_map
    end

    # Returns the balance of the provided Asset. Balances are aggregated across all Addresses in the Wallet.
    # @param asset_id [Symbol] The ID of the Asset to retrieve the balance for
    # @return [BigDecimal] The balance of the Asset
    def get_balance(asset_id)
      normalized_asset_id = if %i[wei gwei].include?(asset_id)
                              :eth
                            else
                              asset_id
                            end

      eth_balance = list_balances[normalized_asset_id] || BigDecimal(0)

      case asset_id
      when :eth
        eth_balance
      when :gwei
        eth_balance * Coinbase::GWEI_PER_ETHER
      when :wei
        eth_balance * Coinbase::WEI_PER_ETHER
      else
        BigDecimal(0)
      end
    end

    # Transfers the given amount of the given Asset to the given address. Only same-Network Transfers are supported.
    # Currently only the default_address is used to source the Transfer.
    # @param amount [Integer, Float, BigDecimal] The amount of the Asset to send
    # @param asset_id [Symbol] The ID of the Asset to send
    # @param destination [Wallet | Address | String] The destination of the transfer. If a Wallet, sends to the Wallet's
    #  default address. If a String, interprets it as the address ID.
    # @return [Transfer] The hash of the Transfer transaction.
    def transfer(amount, asset_id, destination)
      if destination.is_a?(Wallet)
        raise ArgumentError, 'Transfer must be on the same Network' if destination.network_id != @network_id

        destination = destination.default_address.address_id
      elsif destination.is_a?(Address)
        raise ArgumentError, 'Transfer must be on the same Network' if destination.network_id != @network_id

        destination = destination.address_id
      end

      default_address.transfer(amount, asset_id, destination)
    end
  end
end
