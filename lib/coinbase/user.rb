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

    # Enumerates the Wallets belonging to the User.
    # @return [Enumerator<Coinbase::Wallet>] the Wallets belonging to the User
    def wallets
      Wallet.list
    end

    # Returns the Wallet with the given ID.
    # @param wallet_id [String] the ID of the Wallet
    # @return [Coinbase::Wallet] the unhydrated Wallet
    def wallet(wallet_id)
      Wallet.fetch(wallet_id)
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
  end
end
