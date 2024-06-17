# frozen_string_literal: true

module Coinbase
  # A representation of an Asset.
  class Asset
    # Retuns whether the provided asset ID is supported.
    # @param asset_id [Symbol] The Asset ID
    # @return [Boolean] Whether the Asset ID is supported
    def self.supported?(asset_id)
      !!Coinbase::SUPPORTED_ASSET_IDS[asset_id]
    end

    # Converts the amount of the Asset to the atomic units of the primary denomination of the Asset.
    # @param amount [Integer, Float, BigDecimal] The amount to normalize
    # @param asset_id [Symbol] The ID of the Asset being transferred
    # @return [BigDecimal] The normalized amount in atomic units
    def self.to_atomic_amount(amount, asset_id)
      case asset_id
      when :eth
        amount * BigDecimal(Coinbase::WEI_PER_ETHER.to_s)
      when :gwei
        amount * BigDecimal(Coinbase::WEI_PER_GWEI.to_s)
      when :usdc
        amount * BigDecimal(Coinbase::ATOMIC_UNITS_PER_USDC.to_s)
      when :weth
        amount * BigDecimal(Coinbase::WEI_PER_ETHER)
      else
        # TODO: This will not support any other assets until we support fetching the
        # asset from the API by asset ID or support passing whole amounts to the backend.
        amount
      end
    end

    # Returns the primary denomination for the provided Asset ID.
    # For assets with multiple denominations, e.g. eth can also be denominated in wei and gwei,
    # this method will return the primary denomination.
    # e.g. eth.
    # @param asset_id [Symbol] The Asset ID
    # @return [Symbol] The primary denomination for the Asset ID
    def self.primary_denomination(asset_id)
      return :eth if %i[wei gwei].include?(asset_id)

      asset_id
    end

    def self.from_model(asset_model, asset_id: nil)
      raise unless asset_model.is_a?(Coinbase::Client::Asset)

      decimals = asset_model.decimals

      # Handle the non-primary denomination case at the asset level.
      # TODO: Push this logic down to the backend.
      if asset_id && asset_id != Coinbase.to_sym(asset_model.asset_id)
        case asset_id
        when :gwei
          decimals = GWEI_DECIMALS
        when :wei
          decimals = 0
        else
          raise ArgumentError, "Unsupported asset ID: #{asset_id}"
        end
      end

      new(
        network_id: Coinbase.to_sym(asset_model.network_id),
        asset_id: asset_id || Coinbase.to_sym(asset_model.asset_id),
        address_id: asset_model.contract_address,
        decimals: decimals
      )
    end

    # Returns a new Asset object. Do not use this method. Instead, use the Asset constants defined in
    # the Coinbase module.
    # @param network_id [Symbol] The ID of the Network to which the Asset belongs
    # @param asset_id [Symbol] The Asset ID
    # @param address_id [String] (Optional) The Asset's address ID, if one exists
    # @param decimals [Integer] (Optional) The number of decimal places the Asset uses
    def initialize(network_id:, asset_id:, decimals:, address_id: nil)
      @network_id = network_id
      @asset_id = asset_id
      @address_id = address_id
      @decimals = decimals
    end

    attr_reader :network_id, :asset_id, :address_id, :decimals

    def from_atomic_amount(atomic_amount)
      # Return the amount in the whole units of the denomination based on
      # the assets configured decimals.
      BigDecimal(atomic_amount) / BigDecimal(10).power(decimals)
    end

    # Returns a string representation of the Asset.
    # @return [String] a string representation of the Asset
    def to_s
      "Coinbase::Asset{network_id: '#{network_id}', asset_id: '#{asset_id}', decimals: '#{decimals}'" \
        "#{address_id.nil? ? '' : ", address_id: '#{address_id}'"}}"
    end

    # Same as to_s.
    # @return [String] a string representation of the Balance
    def inspect
      to_s
    end
  end
end
