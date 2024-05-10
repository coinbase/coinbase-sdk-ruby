# frozen_string_literal: true

module Coinbase
  # A representation of an Balance.
  class Balance
    # Converts a Coinbase::Client::Balance model to a Coinbase::Balance
    # @param balance_model [Coinbase::Client::Balance] The balance fetched from the API.
    # @return [Balance] The converted Balance object.
    def self.from_model(balance_model)
      asset_id = Coinbase.to_sym(balance_model.asset.asset_id.downcase)

      # TODO: Migrate asset ID handling to the backend.
      amount = case asset_id
               when :eth
                 BigDecimal(balance_model.amount) / BigDecimal(Coinbase::WEI_PER_ETHER)
               when :usdc
                 BigDecimal(balance_model.amount) / BigDecimal(Coinbase::ATOMIC_UNITS_PER_USDC)
               when :weth
                 BigDecimal(balance_model.amount) / BigDecimal(Coinbase::WEI_PER_ETHER)
               else
                 BigDecimal(balance_model.amount)
               end

      new(amount: amount, asset_id: asset_id)
    end

    # Returns a new Asset object. Do not use this method. Instead, use the Asset constants defined in
    # the Coinbase module.
    # @param network_id [Symbol] The ID of the Network to which the Asset belongs
    # @param asset_id [Symbol] The Asset ID
    # @param display_name [String] The Asset's display name
    # @param address_id [String] (Optional) The Asset's address ID, if one exists
    def initialize(amount:, asset_id:)
      @amount = amount
      @asset_id = asset_id
    end

    attr_reader :amount, :asset_id
  end
end
