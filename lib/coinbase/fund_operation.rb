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
      # This takes an optional FundQuote object that can be used to lock in the rate and fees.
      # Without an explicit quote, we will use the current rate and fees.
      # @param address_id [String] The Address ID of the sending Address
      # @param wallet_id [String] The Wallet ID of the sending Wallet
      # @param amount [BigDecimal] The amount of the Asset to send
      # @param network [Coinbase::Network, Symbol] The Network or Network ID of the Asset
      # @param asset_id [Symbol] The Asset ID of the Asset to send
      # @param quote [Coinbase::FundQuote, String] The optional FundQuote to use for the Fund Operation
      # @return [FundOperation] The new pending Fund Operation object
      # @raise [Coinbase::ApiError] If the Fund Operation fails
      def create(wallet_id:, address_id:, amount:, asset_id:, network:, quote: nil)
        network = Coinbase::Network.from_id(network)
        asset = network.get_asset(asset_id)

        model = Coinbase.call_api do
          fund_api.create_fund_operation(
            wallet_id,
            address_id,
            {
              amount: asset.to_atomic_amount(amount).to_i.to_s,
              asset_id: asset.primary_denomination.to_s,
              fund_quote_id: quote_id(quote)
            }.compact
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

      def quote_id(quote)
        return nil if quote.nil?
        return quote.id if quote.is_a?(FundQuote)
        return quote if quote.is_a?(String)

        raise ArgumentError, 'quote must be a FundQuote object or ID'
      end
    end

    # Returns a new Fund Operation object. Do not use this method directly. Instead, use
    # Wallet#fund or Address#fund.
    # @param model [Coinbase::Client::FundOperation] The underlying Fund Operation object
    def initialize(model)
      raise ArgumentError, 'must be a FundOperation' unless model.is_a?(Coinbase::Client::FundOperation)

      @model = model
    end

    # Returns the Fund Operation ID.
    # @return [String] The Fund Operation ID
    def id
      @model.fund_operation_id
    end

    # Returns the Network of the Fund Operation.
    # @return [Coinbase::Network] The Network
    def network
      @network ||= Coinbase::Network.from_id(@model.network_id)
    end

    # Returns the Wallet ID that the fund quote was created for.
    # @return [String] The Wallet ID
    def wallet_id
      @model.wallet_id
    end

    # Returns the Address ID that the fund quote was created for.
    # @return [String] The Address ID
    def address_id
      @model.address_id
    end

    # Returns the Asset of the Fund Operation.
    # @return [Coinbase::Asset] The Asset
    def asset
      amount.asset
    end

    # Returns the amount that the wallet will receive in crypto.
    # @return [Coinbase::CryptoAmount] The crypto amount
    def amount
      @amount ||= CryptoAmount.from_model(@model.crypto_amount)
    end

    # Returns the amount that the wallet's owner will pay in fiat.
    # @return [Coinbase::FiatAmount] The fiat amount
    def fiat_amount
      @fiat_amount ||= FiatAmount.from_model(@model.fiat_amount)
    end

    # Returns the fee that the wallet's owner will pay in fiat.
    # @return [Coinbase::FiatAmount] The fiat buy fee
    def buy_fee
      @buy_fee ||= FiatAmount.from_model(@model.fees.buy_fee)
    end

    # Returns the fee that the wallet's owner will pay in crypto.
    # @return [Coinbase::CryptoAmount] The crypto transfer fee
    def transfer_fee
      @transfer_fee ||= CryptoAmount.from_model(@model.fees.transfer_fee)
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
        fund_api.get_fund_operation(wallet_id, address_id, id)
      end

      self
    end

    # Waits until the Fund Operation is completed or failed by polling the at the given interval.
    # @param interval_seconds [Integer] The interval at which to poll the Network, in seconds
    # @param timeout_seconds [Integer] The maximum amount of time to wait for the Fund Operation to complete, in seconds
    # @return [Coinbase::FundOperation] The completed or failed Fund Operation object
    # @raise [Timeout::Error] If the Fund Operation takes longer than the given timeout
    def wait!(interval_seconds = 1, timeout_seconds = 30)
      start_time = Time.now

      loop do
        reload

        return self if terminal_state?

        raise Timeout::Error, 'Fund Operation timed out' if Time.now - start_time > timeout_seconds

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
        status: status,
        crypto_amount: amount,
        fiat_amount: fiat_amount,
        buy_fee: buy_fee,
        transfer_fee: transfer_fee
      )
    end

    # Same as to_s.
    # @return [String] a String representation of the Fund Operation.
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
