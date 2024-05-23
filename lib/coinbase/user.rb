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
    def id
      @model.id
    end

    # Creates a new Wallet belonging to the User.
    # @param network_id [String] (Optional) the ID of the blockchain network. Defaults to 'base-sepolia'.
    # @return [Coinbase::Wallet] the new Wallet
    def create_wallet(create_wallet_options = {})
      # For ruby 2.7 compatibility we cannot pass in keyword args when the create wallet
      # options is empty
      return Wallet.create if create_wallet_options.empty?

      Wallet.create(**create_wallet_options)
    end

    # Imports a Wallet belonging to the User.
    # @param data [Coinbase::Wallet::Data] the Wallet data to import
    # @return [Coinbase::Wallet] the imported Wallet
    def import_wallet(data)
      Wallet.import(data)
    end

    # Lists the Wallets belonging to the User.
    # @param page_size [Integer] (Optional) the number of Wallets to return per page. Defaults to 10
    # @param next_page_token [String] (Optional) the token for the next page of Wallets
    # @return [Array<Coinbase::Wallet, String>] the Wallets belonging to the User and the pagination token, if
    #   any.
    def wallets(page_size: 10, next_page_token: nil)
      opts = {
        limit: page_size
      }

      opts[:page] = next_page_token unless next_page_token.nil?

      wallet_list = Coinbase.call_api do
        wallets_api.list_wallets(opts)
      end

      # A map from wallet_id to address models.
      address_model_map = {}

      wallet_list.data.each do |wallet_model|
        addresses_list = Coinbase.call_api do
          addresses_api.list_addresses(wallet_model.id, { limit: Coinbase::Wallet::MAX_ADDRESSES })
        end

        address_model_map[wallet_model.id] = addresses_list.data
      end

      wallets = wallet_list.data.map do |wallet_model|
        Wallet.new(wallet_model, seed: '', address_models: address_model_map[wallet_model.id])
      end

      return [wallets, wallet_list.next_page]
    end

    # Returns the Wallet with the given ID.
    # @param wallet_id [String] the ID of the Wallet
    # @return [Coinbase::Wallet] the unhydrated Wallet
    def wallet(wallet_id)
      wallet_model = Coinbase.call_api do
        wallets_api.get_wallet(wallet_id)
      end

      addresses_list = Coinbase.call_api do
        addresses_api.list_addresses(wallet_model.id, { limit: Coinbase::Wallet::MAX_ADDRESSES })
      end

      Wallet.new(wallet_model, seed: '', address_models: addresses_list.data)
    end

    # Returns a string representation of the User.
    # @return [String] a string representation of the User
    def to_s
      "Coinbase::User{user_id: '#{id}'}"
    end

    # Same as to_s.
    # @return [String] a string representation of the User
    def inspect
      to_s
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
