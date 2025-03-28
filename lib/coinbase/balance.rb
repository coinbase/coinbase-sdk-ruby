# frozen_string_literal: true

module Coinbase
  # A representation of an Balance.
  class Balance
    # Converts a Coinbase::Client::Balance model to a Coinbase::Balance
    # @param balance_model [Coinbase::Client::Balance] The balance fetched from the API.
    # @return [Balance] The converted Balance object.
    def self.from_model(balance_model)
      asset = Coinbase::Asset.from_model(balance_model.asset)

      new(amount: asset.from_atomic_amount(balance_model.amount), asset: asset)
    end

    # Converts a Coinbase::Client::Balance model and asset ID to a Coinbase::Balance
    # This can be used to specify a non-primary denomination that we want the balance
    # to be converted to.
    # @param balance_model [Coinbase::Client::Balance] The balance fetched from the API.
    # @param asset_id [Symbol] The Asset ID of the denomination we want returned.
    # @return [Balance] The converted Balance object.
    def self.from_model_and_asset_id(balance_model, asset_id)
      asset = Coinbase::Asset.from_model(balance_model.asset, asset_id: asset_id)

      new(
        amount: asset.from_atomic_amount(balance_model.amount),
        asset: asset,
        asset_id: asset_id
      )
    end

    # Returns a new Balance object. Do not use this method. Instead, use Balance.from_model or
    # Balance.from_model_and_asset_id.
    # @param amount [BigDecimal] The amount of the Asset
    # @param asset_id [Symbol] The Asset ID
    def initialize(amount:, asset:, asset_id: nil)
      @amount = amount
      @asset = asset
      @asset_id = asset_id || asset.asset_id
    end

    attr_reader :amount, :asset, :asset_id

    # Returns a string representation of the Balance.
    # @return [String] a string representation of the Balance
    def to_s
      Coinbase.pretty_print_object(self.class, amount: amount.to_s('F'), asset_id: asset_id)
    end

    # Same as to_s.
    # @return [String] a string representation of the Balance
    def inspect
      to_s
    end
  end
end
