# frozen_string_literal: true

require_relative 'client'
require_relative 'wallet'

module Coinbase
  # A representation of a User. Users have Wallets, which can hold balances of Assets.
  class User
    # Returns a new User object.
    # @param model [Coinbase::Client::User] the underlying User object
    # @param wallets_api [Coinbase::Client::WalletsApi] the Wallets API to use
    # @param addresses_api [Coinbase::Client::AddressesApi] the Addresses API to use
    def initialize(model, wallets_api, addresses_api)
      @model = model
      @wallets_api = wallets_api
      @addresses_api = addresses_api
    end

    # Returns the User ID.
    # @return [String] the User ID
    def user_id
      @model.id
    end

    # Creates a new Wallet belonging to the User.
    # @return [Coinbase::Wallet] the new Wallet
    def create_wallet
      create_wallet_request = {
        wallet: {
          # TODO: Don't hardcode this.
          network_id: 'base-sepolia'
        }
      }
      opts = { create_wallet_request: create_wallet_request }

      model = @wallets_api.create_wallet(opts)

      Wallet.new(model, @wallets_api, @addresses_api)
    end

    # Imports a Wallet belonging to the User.
    # @param data [Coinbase::Wallet::Data] the Wallet data to import
    # @return [Coinbase::Wallet] the imported Wallet
    def import_wallet(data)
      model = @wallets_api.get_wallet(data.wallet_id)
      address_count = @addresses_api.list_addresses(model.id).total_count
      Wallet.new(model, @wallets_api, @addresses_api, seed: data.seed, address_count: address_count)
    end

    # Lists the IDs of the Wallets belonging to the User.
    # @return [Array<String>] the IDs of the Wallets belonging to the User
    def list_wallet_ids
      wallets = @wallets_api.list_wallets
      wallets.map(&:id)
    end
  end
end
