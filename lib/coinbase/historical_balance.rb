# frozen_string_literal: true

module Coinbase
  # A representation of an HistoricalBalance.
  class HistoricalBalance
    # Converts a Coinbase::Client::HistoricalBalance model to a Coinbase::HistoricalBalance
    # @param historical_balance_model [Coinbase::Client::HistoricalBalance] The historical balance fetched from the API.
    # @return [HistoricalBalance] The converted HistoricalBalance object.
    def self.from_model(historical_balance_model)
      asset = Coinbase::Asset.from_model(historical_balance_model.asset)

      new(
        amount: asset.from_atomic_amount(historical_balance_model.amount),
        block_height: BigDecimal(historical_balance_model.block_height),
        block_hash: historical_balance_model.block_hash,
        asset: asset
      )
    end

    # Returns a new HistoricalBalance object. Do not use this method. Instead, use Balance.from_model or
    # Balance.from_model_and_asset_id.
    # @param amount [BigDecimal] The amount of the Asset
    # @param block_height [BigDecimal] The block height at which the balance was recorded
    # @param block_hash [String] The block hash at which the balance was recorded
    # @param asset [Asset] The asset we want to fetch
    def initialize(amount:, block_height:, block_hash:, asset:)
      @amount = amount
      @block_height = block_height
      @block_hash = block_hash
      @asset = asset
    end

    attr_reader :amount, :block_height, :block_hash, :asset

    # Returns a string representation of the HistoricalBalance.
    # @return [String] a string representation of the HistoricalBalance
    def to_s
      Coinbase.pretty_print_object(
        self.class,
        amount: amount.to_i,
        block_height: block_height.to_i,
        block_hash: block_hash,
        asset: asset
      )
    end

    # Same as to_s.
    # @return [String] a string representation of the HistoricalBalance
    def inspect
      to_s
    end
  end
end
