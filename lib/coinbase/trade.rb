# frozen_string_literal: true

require_relative 'constants'
require 'bigdecimal'
require 'eth'

module Coinbase
  # A representation of a Trade, which trades an amount of an Asset to another Asset on a Network.
  # The fee is assumed to be paid in the native Asset of the Network.
  # Trades should be created through Wallet#trade or # Address#trade.
  class Trade
    # Returns a new Trade object. Do not use this method directly. Instead, use Wallet#trade or
    # Address#trade.
    # @param model [Coinbase::Client::Trade] The underlying Trade object
    def initialize(model)
      raise unless model.is_a?(Coinbase::Client::Trade)

      @model = model
    end

    # Returns the Trade ID.
    # @return [String] The Trade ID
    def id
      @model.trade_id
    end

    # Returns the Network ID of the Trade.
    # @return [Symbol] The Network ID
    def network_id
      Coinbase.to_sym(@model.network_id)
    end

    # Returns the Wallet ID of the Trade.
    # @return [String] The Wallet ID
    def wallet_id
      @model.wallet_id
    end

    # Returns the Address ID of the Trade.
    # @return [String] The Address ID
    def address_id
      @model.address_id
    end

    # Returns the From Asset ID of the Trade.
    # @return [Symbol] The From Asset ID
    def from_asset_id
      @model.from_asset.asset_id.to_sym
    end

    # Returns the amount of the from asset for the Trade.
    # @return [BigDecimal] The amount of the from asset
    def from_amount
      BigDecimal(@model.from_amount) / BigDecimal(10).power(@model.from_asset.decimals)
    end

    # Returns the To Asset ID of the Trade.
    # @return [Symbol] The To Asset ID
    def to_asset_id
      @model.to_asset.asset_id.to_sym
    end

    # Returns the amount of the to asset for the Trade.
    # @return [BigDecimal] The amount of the to asset
    def to_amount
      BigDecimal(@model.to_amount) / BigDecimal(10).power(@model.to_asset.decimals)
    end

    # Returns the Trade transaction.
    # @return [Coinbase::Transaction] The Trade transaction
    def transaction
      @transaction ||= Coinbase::Transaction.new(@model.transaction)
    end

    def approve_transaction
      @approve_transaction ||= @model.approve_transaction ? Coinbase::Transaction.new(@model.approve_transaction) : nil
    end

    # Returns the status of the Trade.
    # @return [Symbol] The status
    def status
      transaction.status
    end

    # Waits until the Trade is completed or failed by polling the Network at the given interval. Raises a
    # Timeout::Error if the Trade takes longer than the given timeout.
    # @param interval_seconds [Integer] The interval at which to poll the Network, in seconds
    # @param timeout_seconds [Integer] The maximum amount of time to wait for the Trade to complete, in seconds
    # @return [Trade] The completed Trade object
    def wait!(interval_seconds = 0.2, timeout_seconds = 10)
      start_time = Time.now

      loop do
        reload

        # Wait for the trade transaction to be in a terminal state.
        # The approve transaction is optional and must last first, so we don't need to wait for it.
        # We may want to handle a situation where the approve transaction fails and the
        # trade transaction does not ever get broadcast.
        break if transaction.terminal_state?

        raise Timeout::Error, 'Trade timed out' if Time.now - start_time > timeout_seconds

        self.sleep interval_seconds
      end

      self
    end

    # Reloads the Trade model with the latest version from the server side.
    # @return [Trade] The most recent version of Trade from the server.
    def reload
      @model = Coinbase.call_api do
        trades_api.get_trade(wallet_id, address_id, id)
      end

      # Update the memoized transaction.
      @transaction = Coinbase::Transaction.new(@model.transaction)

      # Update the memoized approve transaction if it exists.
      @approve_transaction = @model.approve_transaction ? Coinbase::Transaction.new(@model.approve_transaction) : nil

      self
    end

    # Returns a String representation of the Trade.
    # @return [String] a String representation of the Trade
    def to_s
      "Coinbase::Trade{transfer_id: '#{id}', network_id: '#{network_id}', " \
        "address_id: '#{address_id}', from_asset_id: '#{from_asset_id}', " \
        "to_asset_id: '#{to_asset_id}', from_amount: '#{from_amount}', " \
        "to_amount: '#{to_amount}' status: '#{status}'}"
    end

    # Same as to_s.
    # @return [String] a String representation of the Trade
    def inspect
      to_s
    end

    private

    def trades_api
      @trades_api ||= Coinbase::Client::TradesApi.new(Coinbase.configuration.api_client)
    end
  end
end
