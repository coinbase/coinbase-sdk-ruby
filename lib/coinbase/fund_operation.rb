# frozen_string_literal: true

require_relative 'constants'
require 'bigdecimal'
require 'eth'

module Coinbase
  # A representation of a Fund Operation, which buys funds from the Coinbase platform,
  # and sends then to the developer's address.
  class FundOperation
    # A representation of a Fund Operation status.
    module Status
      # The Fund Operation is being processed.
      PENDING = 'pending'

      # The Fund Operation is complete.
      COMPLETE = 'complete'

      # The Fund Operation has failed for some reason.
      FAILED = 'failed'

      # The states that are considered terminal on-chain.
      TERMINAL_STATES = [COMPLETE, FAILED].freeze
    end

    class << self
      # Creates a new Fund Operation object.
      # @param address_id [String] The Address ID of the sending Address
      # @param wallet_id [String] The Wallet ID of the sending Wallet
      # @param amount [BigDecimal] The amount of the Asset to send
      # @param network [Coinbase::Network, Symbol] The Network or Network ID of the Asset
      # @param asset_id [Symbol] The Asset ID of the Asset to send
      # @return [FundOperation] The new pending FundOperation object
      # @raise [Coinbase::ApiError] If the FundOperation fails
      def create(wallet_id:, address_id:, amount:, asset_id:, network:)
        network = Coinbase::Network.from_id(network)
        asset = network.get_asset(asset_id)

        model = Coinbase.call_api do
          fund_api.create_fund_operation(
            wallet_id,
            address_id,
            {
              amount: asset.to_atomic_amount(amount).to_i.to_s,
              asset_id: asset.primary_denomination.to_s,
            }
          )
        end

        new(model)
      end

      # Enumerates the fund operation for a given address belonging to a wallet.
      # The result is an enumerator that lazily fetches from the server, and can be iterated over,
      # converted to an array, etc...
      # @return [Enumerable<Coinbase::FundOperation>] Enumerator that returns fund operations
      def list(wallet_id:, address_id:)
        Coinbase::Pagination.enumerate(
          ->(page) { fetch_page(wallet_id, address_id, page) }
        ) do |fund_operation|
          new(fund_operation)
        end
      end

      private

      def fund_api
        Coinbase::Client::FundApi.new(Coinbase.configuration.api_client)
      end

      def fetch_page(wallet_id, address_id, page)
        fund_api.list_fund_operations(
          wallet_id,
          address_id,
          limit: DEFAULT_PAGE_LIMIT,
          page: page
        )
      end
    end

    # Returns a new FundOperation object. Do not use this method directly. Instead, use
    # Wallet#fund or Address#fund.
    # @param model [Coinbase::Client::FundOperation] The underlying FundOperation object
    def initialize(model)
      raise unless model.is_a?(Coinbase::Client::FundOperation)

      @model = model
    end

    # Returns the FundOperation ID.
    # @return [String] The FundOperation ID
    def id
      @model.fund_operation_id
    end

    # Returns the Network of the FundOperation.
    # @return [Coinbase::Network] The Network
    def network
      @network ||= Coinbase::Network.from_id(@model.network_id)
    end

    # Returns the Wallet ID of the FundOperation.
    # @return [String] The Wallet ID
    def wallet_id
      @model.wallet_id
    end

    # Returns the From Address ID of the FundOperation.
    # @return [String] The From Address ID
    def address_id
      @model.address_id
    end

    # Returns the Asset of the FundOperation.
    # @return [Coinbase::Asset] The Asset
    def asset
      @asset ||= Coinbase::Asset.from_model(@model.crypto_amount.asset)
    end

    # Returns the amount of the asset for the Transfer.
    # @return [BigDecimal] The amount of the asset
    def amount
      BigDecimal(@model.crypto_amount.amount) / BigDecimal(10).power(@model.crypto_amount.asset.decimals)
    end

    # Returns the amount of Fiat the FundOperation will cost (inclusive of fees).
    # @return [BigDecimal] The amount of Fiat
    def fiat_amount
      BigDecimal(@model.fiat_amount.amount)
    end

    # Returns the Fiat currency of the FundOperation.
    # @return [String] The Fiat currency
    def fiat_currency
      @model.fiat_amount.currency
    end

    # Returns the status of the Fund Operation.
    # @return [Symbol] The status
    def status
      @model.status
    end

    # Reload reloads the Transfer model with the latest version from the server side.
    # @return [Transfer] The most recent version of Transfer from the server.
    def reload
      @model = Coinbase.call_api do
        fund_api.get_fund_operation(wallet_id, from_address_id, id)
      end

      self
    end

    # Waits until the Transfer is completed or failed by polling the Network at the given interval. Raises a
    # Timeout::Error if the Transfer takes longer than the given timeout.
    # @param interval_seconds [Integer] The interval at which to poll the Network, in seconds
    # @param timeout_seconds [Integer] The maximum amount of time to wait for the Transfer to complete, in seconds
    # @return [Transfer] The completed Transfer object
    def wait!(interval_seconds = 0.2, timeout_seconds = 20)
      start_time = Time.now

      loop do
        reload

        return self if terminal_state?

        raise Timeout::Error, 'Transfer timed out' if Time.now - start_time > timeout_seconds

        self.sleep interval_seconds
      end

      self
    end

    # Returns a String representation of the Fund Operation.
    # @return [String] a String representation of the Fund Operation
    def to_s
      Coinbase.pretty_print_object(
        self.class,
        id: id,
        network_id: network.id,
        wallet_id: wallet_id,
        address_id: address_id,
        amount: amount,
        asset_id: asset.id,
        status: status
      )
    end

    # Same as to_s.
    # @return [String] a String representation of the Transfer
    def inspect
      to_s
    end

    private

    # Returns whether the Fund Operation is in a terminal state.
    # @return [Boolean] Whether the Fund Operation is in a terminal state
    def terminal_state?
      Status::TERMINAL_STATES.include?(status)
    end

    def fund_api
      @fund_api ||= Coinbase::Client::FundApi.new(Coinbase.configuration.api_client)
    end
  end
end
