# frozen_string_literal: true

require 'bigdecimal'
require 'eth'

module Coinbase
  # A representation of a blockchain Address that belongs to a Coinbase::Wallet.
  # Addresses are used to send and receive Assets, and should be created using
  # Wallet#create_address. Addresses require an Eth::Key to sign transaction data.
  class WalletAddress < Address
    # Returns a new Address object. Do not use this method directly. Instead, use Wallet#create_address, or use
    # the Wallet's default_address.
    # @param model [Coinbase::Client::Address] The underlying Address object
    # @param key [Eth::Key] The key backing the Address. Can be nil.
    def initialize(model, key)
      @model = model
      @key = key

      super(model.network_id, model.address_id)
    end

    # Returns the Wallet ID of the Address.
    # @return [String] The Wallet ID
    def wallet_id
      @model.wallet_id
    end

    # Sets the private key backing the Address. This key is used to sign transactions.
    # @param key [Eth::Key] The key backing the Address
    def key=(key)
      raise 'Private key is already set' unless @key.nil?

      @key = key
    end

    # Transfers the given amount of the given Asset to the specified address or wallet.
    # Only same-network Transfers are supported.
    # @param amount [Integer, Float, BigDecimal] The amount of the Asset to send.
    # @param asset_id [Symbol] The ID of the Asset to send. For Ether, :eth, :gwei, and :wei are supported.
    # @param destination [Wallet | Address | String] The destination of the transfer. If a Wallet, sends to the Wallet's
    #  default address. If a String, interprets it as the address ID.
    # @return [Coinbase::Transfer] The Transfer object.
    def transfer(amount, asset_id, destination)
      ensure_can_sign!
      ensure_sufficient_balance!(amount, asset_id)

      transfer = Transfer.create(
        address_id: id,
        amount: amount,
        asset_id: asset_id,
        destination: destination,
        network_id: network_id,
        wallet_id: wallet_id
      )

      # If a server signer is managing keys, it will sign and broadcast the underlying transfer transaction out of band.
      return transfer if Coinbase.use_server_signer?

      transfer.transaction.sign(@key)

      transfer.broadcast!
      transfer
    end

    # Trades the given amount of the given Asset for another Asset.
    # Only same-network Trades are supported.
    # @param amount [Integer, Float, BigDecimal] The amount of the Asset to send.
    # @param from_asset_id [Symbol] The ID of the Asset to trade from. For Ether, :eth, :gwei, and :wei are supported.
    # @param to_asset_id [Symbol] The ID of the Asset to trade to. For Ether, :eth, :gwei, and :wei are supported.
    # @return [Coinbase::Trade] The Trade object.
    def trade(amount, from_asset_id, to_asset_id)
      ensure_can_sign!
      ensure_sufficient_balance!(amount, from_asset_id)

      trade = Trade.create(
        address_id: id,
        amount: amount,
        from_asset_id: from_asset_id,
        to_asset_id: to_asset_id,
        network_id: network_id,
        wallet_id: wallet_id
      )

      # If a server signer is managing keys, it will sign and broadcast the underlying trade transaction out of band.
      return trade if Coinbase.use_server_signer?

      trade.transactions.each do |tx|
        tx.sign(@key)
      end

      trade.broadcast!
      trade
    end

    # Returns whether the Address has a private key backing it to sign transactions.
    # @return [Boolean] Whether the Address has a private key backing it to sign transactions.
    def can_sign?
      !@key.nil?
    end

    # Exports the Address's private key to a hex string.
    # @return [String] The Address's private key as a hex String
    def export
      raise 'Cannot export key without private key loaded' if @key.nil?

      @key.private_hex
    end

    # Enumerates the transfers associated with the address.
    # The result is an enumerator that lazily fetches from the server, and can be iterated over,
    # converted to an array, etc...
    # @return [Enumerable<Coinbase::Transfer>] Enumerator that returns the address's transfers
    def transfers
      Transfer.list(wallet_id: wallet_id, address_id: id)
    end

    # Enumerates the trades associated with the address.
    # The result is an enumerator that lazily fetches from the server, and can be iterated over,
    # converted to an array, etc...
    # @return [Enumerable<Coinbase::Trade>] Enumerator that returns the address's trades
    def trades
      Trade.list(wallet_id: wallet_id, address_id: id)
    end

    # Returns a String representation of the WalletAddress.
    # @return [String] a String representation of the WalletAddress
    def to_s
      "Coinbase::Address{id: '#{id}', network_id: '#{network_id}', wallet_id: '#{wallet_id}'}"
    end

    private

    def ensure_can_sign!
      return if Coinbase.use_server_signer?
      return if can_sign?

      raise AddressCannotSignError
    end

    def ensure_sufficient_balance!(amount, asset_id)
      current_balance = balance(asset_id)

      return unless current_balance < amount

      raise InsufficientFundsError.new(amount, current_balance)
    end
  end
end
