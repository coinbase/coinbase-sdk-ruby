# frozen_string_literal: true

module Coinbase
  # A representation of a CryptoAmount that includes the amount and asset.
  class CryptoAmount
    # Converts a Coinbase::Client::CryptoAmount model to a Coinbase::CryptoAmount
    # @param amount_model [Coinbase::Client::CryptoAmount] The crypto amount from the API.
    # @return [CryptoAmount] The converted CryptoAmount object.
    def self.from_model(amount_model)
      asset = Coinbase::Asset.from_model(amount_model.asset)

      new(amount: asset.from_atomic_amount(amount_model.amount), asset: asset)
    end

    # Converts a Coinbase::Client::CryptoAmount model and asset ID to a Coinbase::CryptoAmount
    # This can be used to specify a non-primary denomination that we want the amount
    # to be converted to.
    # @param amount_model [Coinbase::Client::CryptoAmount] The crypto amount from the API.
    # @param asset_id [Symbol] The Asset ID of the denomination we want returned.
    # @return [CryptoAmount] The converted CryptoAmount object.
    def self.from_model_and_asset_id(amount_model, asset_id)
      asset = Coinbase::Asset.from_model(amount_model.asset, asset_id: asset_id)

      new(
        amount: asset.from_atomic_amount(amount_model.amount),
        asset: asset,
        asset_id: asset_id
      )
    end

    # Returns a new CryptoAmount object. Do not use this method.
    # Instead, use CryptoAmount.from_model or CryptoAmount.from_model_and_asset_id.
    # @param amount [BigDecimal] The amount of the Asset
    # @param asset [Coinbase::Asset] The Asset
    # @param asset_id [Symbol] The Asset ID
    def initialize(amount:, asset:, asset_id: nil)
      @amount = amount
      @asset = asset
      @asset_id = asset_id || asset.asset_id
    end

    attr_reader :amount, :asset, :asset_id

    # Returns the amount in atomic units.
    # @return [BigDecimal] the amount in atomic units
    def to_atomic_amount
      asset.to_atomic_amount(amount)
    end

    # Returns a string representation of the CryptoAmount.
    # @return [String] a string representation of the CryptoAmount
    def to_s
      Coinbase.pretty_print_object(self.class, amount: amount.to_s('F'), asset_id: asset_id)
    end

    # Same as to_s.
    # @return [String] a string representation of the CryptoAmount
    def inspect
      to_s
    end
  end
end
