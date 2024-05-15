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

    # Transfers the given amount of the given Asset to the given address. Only same-Network Transfers are supported.
    # @param amount [Integer, Float, BigDecimal] The amount of the Asset to send.
    # @param asset_id [Symbol] The ID of the Asset to send. For Ether, :eth, :gwei, and :wei are supported.
    # @param destination [Wallet | Address | String] The destination of the transfer. If a Wallet, sends to the Wallet's
    #  default address. If a String, interprets it as the address ID.
    # @return [String] The hash of the Transfer transaction.
    def transfer(amount, asset_id, destination)
      raise 'Cannot transfer from address without private key loaded' if @key.nil?

      raise ArgumentError, "Unsupported asset: #{asset_id}" unless Coinbase::Asset.supported?(asset_id)

      if destination.is_a?(Wallet)
        raise ArgumentError, 'Transfer must be on the same Network' if destination.network_id != network_id

        destination = destination.default_address.id
      elsif destination.is_a?(Address)
        raise ArgumentError, 'Transfer must be on the same Network' if destination.network_id != network_id

        destination = destination.id
      end

      current_balance = balance(asset_id)
      if current_balance < amount
        raise ArgumentError, "Insufficient funds: #{amount} requested, but only #{current_balance} available"
      end

      create_transfer_request = {
        amount: Coinbase::Asset.to_atomic_amount(amount, asset_id).to_i.to_s,
        network_id: network_id,
        asset_id: Coinbase::Asset.primary_denomination(asset_id).to_s,
        destination: destination
      }

      transfer_model = Coinbase.call_api do
        transfers_api.create_transfer(wallet_id, id, create_transfer_request)
      end

      transfer = Coinbase::Transfer.new(transfer_model)

      transaction = transfer.transaction
      transaction.sign(@key)

      signed_payload = transaction.hex

      broadcast_transfer_request = {
        signed_payload: signed_payload
      }

      transfer_model = Coinbase.call_api do
        transfers_api.broadcast_transfer(wallet_id, id, transfer.id, broadcast_transfer_request)
      end

      Coinbase::Transfer.new(transfer_model)
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
        puts "fetch transfers page: #{page}"
        response = Coinbase.call_api do
          transfers_api.list_transfers(wallet_id, id, { limit: 100, page: page })
        end

        transfers.concat(response.data.map { |transfer| Coinbase::Transfer.new(transfer) }) if response.data

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
  end
end
