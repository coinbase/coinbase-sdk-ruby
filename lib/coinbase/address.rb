# frozen_string_literal: true

require_relative 'balance_map'
require_relative 'constants'
require_relative 'wallet'
require 'bigdecimal'
require 'eth'
require 'jimson'

module Coinbase
  # A representation of a blockchain Address, which is a user-controlled account on a Network. Addresses are used to
  # send and receive Assets, and should be created using Wallet#create_address. Addresses require an
  # Eth::Key to sign transaction data.
  class Address
    # Returns a new Address object. Do not use this method directly. Instead, use Wallet#create_address, or use
    # the Wallet's default_address.
    # @param model [Coinbase::Client::Address] The underlying Address object
    # @param key [Eth::Key] The key backing the Address. Can be nil.
    def initialize(model, key)
      @model = model
      @key = key
    end

    # Returns the Network ID of the Address.
    # @return [Symbol] The Network ID
    def network_id
      Coinbase.to_sym(@model.network_id)
    end

    # Returns the Wallet ID of the Address.
    # @return [String] The Wallet ID
    def wallet_id
      @model.wallet_id
    end

    # Returns the Address ID.
    # @return [String] The Address ID
    def id
      @model.address_id
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
      destination_address, destination_network = destination_address_and_network(destination)

      validate_can_transfer!(amount, asset_id, destination_network)

      transfer = create_transfer(amount, asset_id, destination_address)

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
      validate_can_trade!(amount, from_asset_id)

      trade = create_trade(amount, from_asset_id, to_asset_id)

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

    # Returns a String representation of the Address.
    # @return [String] a String representation of the Address
    def to_s
      "Coinbase::Address{id: '#{id}', network_id: '#{network_id}', wallet_id: '#{wallet_id}'}"
    end

    # Same as to_s.
    # @return [String] a String representation of the Address
    def inspect
      to_s
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

    # Returns all of the transfers associated with the address.
    # @return [Array<Coinbase::Transfer>] The transfers associated with the address
    def transfers
      transfers = []
      page = nil

      loop do
        response = Coinbase.call_api do
          transfers_api.list_transfers(wallet_id, id, { limit: 100, page: page })
        end

        break if response.data.empty?

        transfers.concat(response.data.map { |transfer| Coinbase::Transfer.new(transfer) })

        break unless response.has_more

        page = response.next_page
      end

      transfers
    end

    private

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

    def validate_can_transfer!(amount, asset_id, destination_network_id)
      raise 'Cannot transfer from address without private key loaded' unless can_sign? || Coinbase.use_server_signer?

      raise ArgumentError, 'Transfer must be on the same Network' unless destination_network_id == network_id

      current_balance = balance(asset_id)

      return unless current_balance < amount

      raise ArgumentError, "Insufficient funds: #{amount} requested, but only #{current_balance} available"
    end

    def create_transfer(amount, asset_id, destination)
      create_transfer_request = {
        # TODO: Handle non-atomic amounts for all assets. For an arbitrary asset,
        # we may not know the precision until we make a call to the backend.
        amount: Coinbase::Asset.to_atomic_amount(amount, asset_id).to_i.to_s,
        network_id: network_id,
        asset_id: Coinbase::Asset.primary_denomination(asset_id).to_s,
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

    def validate_can_trade!(amount, from_asset_id)
      raise 'Cannot trade from address without private key loaded' unless can_sign?

      current_balance = balance(from_asset_id)

      return unless current_balance < amount

      raise ArgumentError, "Insufficient funds: #{amount} requested, but only #{current_balance} available"
    end

    def create_trade(amount, from_asset_id, to_asset_id)
      create_trade_request = {
        amount: Coinbase::Asset.to_atomic_amount(amount, from_asset_id).to_i.to_s,
        from_asset_id: Coinbase::Asset.primary_denomination(from_asset_id).to_s,
        to_asset_id: Coinbase::Asset.primary_denomination(to_asset_id).to_s
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
