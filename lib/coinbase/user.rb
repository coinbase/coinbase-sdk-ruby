# frozen_string_literal: true

require_relative 'client'
require_relative 'wallet'

module Coinbase
  # A representation of a User. Users have Wallets, which can hold balances of Assets.
  class User
    # Returns a new User object.
    # @param delegate [Coinbase::Client::User] the underlying User object
    # @param wallets_api [Coinbase::WalletAPI] the Wallets API to use
    def initialize(delegate, wallets_api)
      @delegate = delegate
      @wallets_api = wallets_api
    end

    # Returns the User ID.
    # @return [String] the User ID
    def user_id
      @delegate.id
    end

    # Creates a new Wallet belonging to the User.
    # @return [Coinbase::Wallet] the new Wallet
    def create_wallet()
      create_wallet_request = {
        :wallet => {
          # TODO: Don't hardcode this.
          :network_id => 'base-sepolia'
        }
      }
      opts = { :create_wallet_request => create_wallet_request }

      wallet = @wallets_api.create_wallet(opts)

      Wallet.new(wallet)
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
