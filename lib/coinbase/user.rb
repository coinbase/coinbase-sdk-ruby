# frozen_string_literal: true

require_relative 'client'
require_relative 'wallet'

module Coinbase
  # A representation of a User. Users have Wallets, which can hold balances of Assets.
  class User
    # Returns a new User object.
    # @param delegate [Coinbase::Client::User] the underlying User object
    def initialize(delegate)
      @delegate = delegate
    end

    # Returns the User ID.
    # @return [String] the User ID
    def user_id
      @delegate.id
    end

    # Creates a new Wallet belonging to the User.
    # @param seed [Integer] (Optional) The seed to use for the Wallet. Expects a 32-byte hexadecimal. If not provided,
    #   a new seed will be generated.
    # @param address_count [Integer] (Optional) The number of addresses to generate for the Wallet. If not provided,
    #   a single address will be generated.
    # @param client [Jimson::Client] (Optional) The JSON RPC client to use for interacting with the Network
    # @return [Coinbase::Wallet] the new Wallet
    def create_wallet(seed: nil, address_count: 1, client: Jimson::Client.new(Coinbase.base_sepolia_rpc_url))
      Wallet.new(seed: seed, address_count: address_count, client: client)
    end

    # Lists the Wallets belonging to the User.
    # @return [Array<Coinbase::Wallet>] the Wallets belonging to the User
    def list_wallets
      raise NotImplementedError
    end

    # Returns the Wallet with the given ID.
    # @param wallet_id [String] the ID of the Wallet to retrieve
    # @return [Coinbase::Wallet] the Wallet
    def get_wallet(wallet_id)
      raise NotImplementedError
    end
  end
end
