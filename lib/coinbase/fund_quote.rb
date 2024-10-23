# frozen_string_literal: true

require_relative 'constants'
require 'bigdecimal'
require 'eth'

module Coinbase
  # A representation of a Fund Operation Quote, which is a quote for a fund operation
  # that buys funds from the Coinbase platform and sends then to the developer's address.
  class FundQuote
    class << self
      # Creates a new Fund Operation Quote object.
      # @param address_id [String] The Address ID of the sending Address
      # @param wallet_id [String] The Wallet ID of the sending Wallet
      # @param amount [BigDecimal] The amount of the Asset to send
      # @param network [Coinbase::Network, Symbol] The Network or Network ID of the Asset
      # @param asset_id [Symbol] The Asset ID of the Asset to send
      # @return [FundQuote] The new Fund Quote object
      # @raise [Coinbase::ApiError] If the Fund Quote fails
      def create(wallet_id:, address_id:, amount:, asset_id:, network:)
        network = Coinbase::Network.from_id(network)
        asset = network.get_asset(asset_id)

        model = Coinbase.call_api do
          fund_api.create_fund_quote(
            wallet_id,
            address_id,
            {
              asset_id: asset.primary_denomination.to_s,
              amount: asset.to_atomic_amount(amount).to_i.to_s
            }
          )
        end

        new(model)
      end

      private

      def fund_api
        Coinbase::Client::FundApi.new(Coinbase.configuration.api_client)
      end
    end

    # Returns a new Fund Quote object. Do not use this method directly.
    # Instead, use Wallet#quote_fund or Address#quote_fund.
    # @param model [Coinbase::Client::FundQuote] The underlying Fund Quote object
    def initialize(model)
      raise ArgumentError, 'must be a FundQuote' unless model.is_a?(Coinbase::Client::FundQuote)

      @model = model
    end

    # Returns the ID of the Fund Quote.
    # @return [String] The Fund Quote ID
    def id
      @model.fund_quote_id
    end

    # Returns the Network the fund quote was created on.
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

    # Returns the Asset of the FundOperation.
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

    # Returns a String representation of the Fund Operation.
    # @return [String] a String representation of the Fund Operation
    def to_s
      Coinbase.pretty_print_object(
        self.class,
        network_id: network.id,
        wallet_id: wallet_id,
        address_id: address_id,
        crypto_amount: amount,
        fiat_amount: fiat_amount,
        buy_fee: buy_fee,
        transfer_fee: transfer_fee
      )
    end

    # Same as to_s.
    # @return [String] a String representation of the Transfer
    def inspect
      to_s
    end
  end
end
