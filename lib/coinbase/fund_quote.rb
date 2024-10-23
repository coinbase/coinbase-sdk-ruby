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
      # @return [FundQuote] The new FundQuote object
      # @raise [Coinbase::ApiError] If the FundQuote fails
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

    # Returns a new FundQuote object. Do not use this method directly.
    # Instead, use Wallet#quote_fund or Address#quote_fund.
    # @param model [Coinbase::Client::FundQuote] The underlying FundQuote object
    def initialize(model)
      raise unless model.is_a?(Coinbase::Client::FundQuote)

      @model = model
    end

    # Returns the Network of the FundOperatoin.
    # @return [Coinbase::Network] The Network
    def network
      @network ||= Coinbase::Network.from_id(@model.network_id)
    end

    # Returns the Wallet ID of the FundOperatoin.
    # @return [String] The Wallet ID
    def wallet_id
      @model.wallet_id
    end

    # Returns the From Address ID of the FundOperatoin.
    # @return [String] The From Address ID
    def address_id
      @model.address_id
    end

    def asset
      @asset ||= Coinbase::Asset.from_model(@model.crypto_amount.asset)
    end

    # Returns the amount of the asset for the Transfer.
    # @return [BigDecimal] The amount of the asset
    def amount
      BigDecimal(@model.crypto_amount.amount) / BigDecimal(10).power(@model.crypto_amount.asset.decimals)
    end

    def fiat_amount
      @model.fiat_amount.amount
    end

    def fiat_currency
      @model.fiat_amount.currency
    end

    # TODO: Add CryptoAmount and FiatAmount types
    def buy_fee
      {
        amount: @model.fees.buy_fee.amount,
        currency: @model.fees.buy_fee.currency
      }
    end

    def transfer_fee
      {
        amount: BigDecimal(@model.fees.transfer_fee.amount) / BigDecimal(10).power(@model.fees.transfer_fee.asset.decimals),
        asset: Coinbase::Asset.from_model(@model.fees.transfer_fee.asset)
      }
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
        crypto_asset: asset.asset_id,
        fiat_amount: fiat_amount,
        fiat_currency: fiat_currency,
        buy_fee: Coinbase.pretty_print_object(buy_fee),
        transfer_fee: Coinbase.pretty_print_object(transfer_fee)
      )
    end

    # Same as to_s.
    # @return [String] a String representation of the Transfer
    def inspect
      to_s
    end
  end
end
