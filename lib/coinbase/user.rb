# frozen_string_literal: true

require_relative 'client'
require_relative 'wallet'

module Coinbase
  # A representation of a User. Users have Wallets, which can hold balances of Assets. Access the default User through
  # Coinbase#default_user.
  class User
    # Returns a new User object. Do not use this method directly. Instead, use Coinbase#default_user.
    # @param model [Coinbase::Client::User] the underlying User object
    def initialize(model)
      @model = model
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

      model = wallets_api.create_wallet(opts)

      Wallet.new(model)
    end

    # Imports a Wallet belonging to the User.
    # @param data [Coinbase::Wallet::Data] the Wallet data to import
    # @return [Coinbase::Wallet] the imported Wallet
    def import_wallet(data)
      model = wallets_api.get_wallet(data.wallet_id)
      address_count = addresses_api.list_addresses(model.id).total_count
      Wallet.new(model, seed: data.seed, address_count: address_count)
    end

    # Imports all wallets belonging to the User with backup persisted to the local file system.
    # @return [[]Coinbase::Wallet] imported wallets.
    def import_wallet_from_store
      file_path = 'seeds.json'
      existing_seed_data= '{}'
      if File.exist?(file_path)
        existing_seed_data = File.read(file_path)
      end
      existing_seeds = JSON.parse(existing_seed_data)
      wallets = []
      existing_seeds.each do |wallet_id, seed|
        data =Coinbase::Wallet::Data.new(wallet_id: wallet_id, seed: seed)
        wallets << import_wallet(data)
      end
      wallets
    end

    # Lists the IDs of the Wallets belonging to the User.
    # @return [Array<String>] the IDs of the Wallets belonging to the User
    def list_wallet_ids
      wallets = wallets_api.list_wallets
      wallets.data.map(&:id)
    end

    private

    def addresses_api
      @addresses_api ||= Coinbase::Client::AddressesApi.new(Coinbase.configuration.api_client)
    end

    def wallets_api
      @wallets_api ||= Coinbase::Client::WalletsApi.new(Coinbase.configuration.api_client)
    end
  end
end
