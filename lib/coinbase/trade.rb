# frozen_string_literal: true

require_relative 'constants'
require 'bigdecimal'
require 'eth'

module Coinbase
  # A representation of a Trade, which trades an amount of an Asset to another Asset on a Network.
  # The fee is assumed to be paid in the native Asset of the Network.
  # Trades should be created through Wallet#trade or # Address#trade.
  class Trade
    class << self
      # Creates a new Trade object.
      # @param address_id [String] The Address ID of the sending Address
      # @param from_asset_id [Symbol] The Asset ID of the Asset to trade from
      # @param to_asset_id [Symbol] The Asset ID of the Asset to trade to
      # @param amount [BigDecimal] The amount of the Asset to send
      # @param network_id [Symbol] The Network ID of the Asset
      # @param wallet_id [String] The Wallet ID of the sending Wallet
      # @return [Send] The new pending Send object
      def create(address_id:, from_asset_id:, to_asset_id:, amount:, network_id:, wallet_id:)
        from_asset = Asset.fetch(network_id, from_asset_id)
        to_asset = Asset.fetch(network_id, to_asset_id)

        model = Coinbase.call_api do
          trades_api.create_trade(
            wallet_id,
            address_id,
            {
              amount: from_asset.to_atomic_amount(amount).to_i.to_s,
              from_asset_id: from_asset.primary_denomination.to_s,
              to_asset_id: to_asset.primary_denomination.to_s
            }
          )
        end

        new(model)
      end

      # Enumerates the trades for a given address belonging to a wallet.
      # The result is an enumerator that lazily fetches from the server, and can be iterated over,
      # converted to an array, etc...
      # @return [Enumerable<Coinbase::Trade>] Enumerator that returns trades
      def list(wallet_id:, address_id:)
        Coinbase::Pagination.enumerate(
          ->(page) { fetch_page(wallet_id, address_id, page) }
        ) do |trade|
          new(trade)
        end
      end

      private

      def trades_api
        Coinbase::Client::TradesApi.new(Coinbase.configuration.api_client)
      end

      def fetch_page(wallet_id, address_id, page)
        trades_api.list_trades(wallet_id, address_id, { limit: DEFAULT_PAGE_LIMIT, page: page })
      end
    end

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

    # Returns the list of Transactions for the Trade.
    def transactions
      [approve_transaction, transaction].compact
    end

    # Returns the status of the Trade.
    # @return [Symbol] The status
    def status
      transaction.status
    end

    # Broadcasts the Trade to the Network.
    # This raises an error if the Trade is not signed.
    # @raise [RuntimeError] If the Trade is not signed
    # @return [Trade] The Trade object
    def broadcast!
      raise TransactionNotSignedError unless transactions.all?(&:signed?)

      payloads = { signed_payload: transaction.raw.hex }

      payloads[:approve_tx_signed_payload] = approve_transaction.raw.hex unless approve_transaction.nil?

      @model = Coinbase.call_api do
        trades_api.broadcast_trade(wallet_id, address_id, id, payloads)
      end

      update_transactions(@model)

      self
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

      update_transactions(@model)

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

    def update_transactions(model)
      # Update the memoized transaction.
      @transaction = Coinbase::Transaction.new(model.transaction)

      return if model.approve_transaction.nil?

      # Update the memoized approve transaction if it exists.
      @approve_transaction = Coinbase::Transaction.new(model.approve_transaction)
    end

    def trades_api
      @trades_api ||= Coinbase::Client::TradesApi.new(Coinbase.configuration.api_client)
    end
  end
end
