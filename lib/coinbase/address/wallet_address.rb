# frozen_string_literal: true

require 'bigdecimal'
require 'eth'
require 'jimson'

module Coinbase
  # A representation of a blockchain Address that belongs to a Coinbase::Wallet.
  # Addresses are used to send and receive Assets, and should be created using
  # Wallet#create_address. Addresses require an Eth::Key to sign transaction data.
  class WalletAddress < Address
    PAGE_LIMIT = 100

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

    # Returns the balances of the Address.
    # @return [BalanceMap] The balances of the Address, keyed by asset ID. Ether balances are denominated
    #  in ETH.
    def balances
      response = Coinbase.call_api do
        addresses_api.list_address_balances(wallet_id, id)
      end

      Coinbase::BalanceMap.from_balances(response.data)
    end

    # Returns the balance of the provided Asset.
    # @param asset_id [Symbol] The Asset to retrieve the balance for
    # @return [BigDecimal] The balance of the Asset
    def balance(asset_id)
      response = Coinbase.call_api do
        addresses_api.get_address_balance(wallet_id, id, Coinbase::Asset.primary_denomination(asset_id).to_s)
      end

      return BigDecimal('0') if response.nil?

      Coinbase::Balance.from_model_and_asset_id(response, asset_id).amount
    end

    # Transfers the given amount of the given Asset to the specified address or wallet.
    # Only same-network Transfers are supported.
    # @param amount [Integer, Float, BigDecimal] The amount of the Asset to send.
    # @param asset_id [Symbol] The ID of the Asset to send. For Ether, :eth, :gwei, and :wei are supported.
    # @param destination [Wallet | Address | String] The destination of the transfer. If a Wallet, sends to the Wallet's
    #  default address. If a String, interprets it as the address ID.
    # @return [Coinbase::Transfer] The Transfer object.
    def transfer(amount, asset_id, destination)
      asset = Asset.fetch(network_id, asset_id)

      destination_address, destination_network = destination_address_and_network(destination)

      validate_can_transfer!(amount, asset, destination_network)

      transfer = create_transfer(amount, asset, destination_address)

      # If a server signer is managing keys, it will sign and broadcast the underlying transfer transaction out of band.
      return transfer if Coinbase.use_server_signer?

      broadcast_transfer(transfer, transfer.transaction.sign(@key))
    end

    # Trades the given amount of the given Asset for another Asset.
    # Only same-network Trades are supported.
    # @param amount [Integer, Float, BigDecimal] The amount of the Asset to send.
    # @param from_asset_id [Symbol] The ID of the Asset to trade from. For Ether, :eth, :gwei, and :wei are supported.
    # @param to_asset_id [Symbol] The ID of the Asset to trade to. For Ether, :eth, :gwei, and :wei are supported.
    # @return [Coinbase::Trade] The Trade object.
    def trade(amount, from_asset_id, to_asset_id)
      from_asset = Asset.fetch(network_id, from_asset_id)
      to_asset = Asset.fetch(network_id, to_asset_id)

      validate_can_trade!(amount, from_asset)

      trade = create_trade(amount, from_asset, to_asset)

      # NOTE: Trading does not yet support server signers at this point.

      payloads = { signed_payload: trade.transaction.sign(@key) }

      payloads[:approve_tx_signed_payload] = trade.approve_transaction.sign(@key) unless trade.approve_transaction.nil?

      broadcast_trade(trade, **payloads)
    end

    # Returns whether the Address has a private key backing it to sign transactions.
    # @return [Boolean] Whether the Address has a private key backing it to sign transactions.
    def can_sign?
      !@key.nil?
    end

    # Requests funds for the address from the faucet and returns the faucet transaction.
    # This is only supported on testnet networks.
    # @return [Coinbase::FaucetTransaction] The successful faucet transaction
    # @raise [Coinbase::FaucetLimitReachedError] If the faucet limit has been reached for the address or user.
    # @raise [Coinbase::Client::ApiError] If an unexpected error occurs while requesting faucet funds.
    def faucet
      Coinbase.call_api do
        Coinbase::FaucetTransaction.new(addresses_api.request_faucet_funds(wallet_id, id))
      end
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
      Coinbase::Pagination.enumerate(lambda(&method(:fetch_transfers_page))) do |transfer|
        Coinbase::Transfer.new(transfer)
      end
    end

    # Enumerates the trades associated with the address.
    # The result is an enumerator that lazily fetches from the server, and can be iterated over,
    # converted to an array, etc...
    # @return [Enumerable<Coinbase::Trade>] Enumerator that returns the address's trades
    def trades
      Coinbase::Pagination.enumerate(lambda(&method(:fetch_trades_page))) do |trade|
        Coinbase::Trade.new(trade)
      end
    end

    # Returns a String representation of the WalletAddress.
    # @return [String] a String representation of the WalletAddress
    def to_s
      "Coinbase::Address{id: '#{id}', network_id: '#{network_id}', wallet_id: '#{wallet_id}'}"
    end

    private

    def fetch_transfers_page(page)
      transfers_api.list_transfers(wallet_id, id, { limit: PAGE_LIMIT, page: page })
    end

    def fetch_trades_page(page)
      trades_api.list_trades(wallet_id, id, { limit: PAGE_LIMIT, page: page })
    end

    def addresses_api
      @addresses_api ||= Coinbase::Client::AddressesApi.new(Coinbase.configuration.api_client)
    end

    def transfers_api
      @transfers_api ||= Coinbase::Client::TransfersApi.new(Coinbase.configuration.api_client)
    end

    def trades_api
      @trades_api ||= Coinbase::Client::TradesApi.new(Coinbase.configuration.api_client)
    end

    def destination_address_and_network(destination)
      return [destination.default_address.id, destination.network_id] if destination.is_a?(Wallet)
      return [destination.id, destination.network_id] if destination.is_a?(Address)

      [destination, network_id]
    end

    def validate_can_transfer!(amount, asset, destination_network_id)
      raise 'Cannot transfer from address without private key loaded' unless can_sign? || Coinbase.use_server_signer?

      raise ArgumentError, 'Transfer must be on the same Network' unless destination_network_id == network_id

      current_balance = balance(asset.asset_id)

      return unless current_balance < amount

      raise ArgumentError, "Insufficient funds: #{amount} requested, but only #{current_balance} available"
    end

    def create_transfer(amount, asset, destination)
      create_transfer_request = {
        amount: asset.to_atomic_amount(amount).to_i.to_s,
        network_id: Coinbase.normalize_network(network_id),
        asset_id: asset.primary_denomination.to_s,
        destination: destination
      }

      transfer_model = Coinbase.call_api do
        transfers_api.create_transfer(wallet_id, id, create_transfer_request)
      end

      Coinbase::Transfer.new(transfer_model)
    end

    def broadcast_transfer(transfer, signed_payload)
      transfer_model = Coinbase.call_api do
        transfers_api.broadcast_transfer(wallet_id, id, transfer.id, { signed_payload: signed_payload })
      end

      Coinbase::Transfer.new(transfer_model)
    end

    def validate_can_trade!(amount, from_asset)
      raise 'Cannot trade from address without private key loaded' unless can_sign?

      current_balance = balance(from_asset.asset_id)

      return unless current_balance < amount

      raise ArgumentError, "Insufficient funds: #{amount} requested, but only #{current_balance} available"
    end

    def create_trade(amount, from_asset, to_asset)
      create_trade_request = {
        amount: from_asset.to_atomic_amount(amount).to_i.to_s,
        from_asset_id: from_asset.primary_denomination.to_s,
        to_asset_id: to_asset.primary_denomination.to_s
      }

      trade_model = Coinbase.call_api do
        trades_api.create_trade(wallet_id, id, create_trade_request)
      end

      Coinbase::Trade.new(trade_model)
    end

    def broadcast_trade(trade, signed_payload:, approve_tx_signed_payload: nil)
      req = { signed_payload: signed_payload }

      req[:approve_transaction_signed_payload] = approve_tx_signed_payload unless approve_tx_signed_payload.nil?

      trade_model = Coinbase.call_api do
        trades_api.broadcast_trade(wallet_id, id, trade.id, req)
      end

      Coinbase::Trade.new(trade_model)
    end
  end
end
