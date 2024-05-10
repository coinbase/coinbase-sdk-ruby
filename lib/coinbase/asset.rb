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
        amount
      end
    end

    # Converts an amount from the atomic value of the primary denomination of the provided Asset ID
    # to whole units of the specified asset ID.
    # @param atomic_amount [BigDecimal] The amount in atomic units
    # @param asset_id [Symbol] The Asset ID
    # @return [BigDecimal] The amount in whole units of the specified asset ID
    def self.from_atomic_amount(atomic_amount, asset_id)
      case asset_id
      when :eth
        atomic_amount / BigDecimal(Coinbase::WEI_PER_ETHER.to_s)
      when :gwei
        atomic_amount / BigDecimal(Coinbase::WEI_PER_GWEI.to_s)
      when :usdc
        atomic_amount / BigDecimal(Coinbase::ATOMIC_UNITS_PER_USDC.to_s)
      when :weth
        atomic_amount / BigDecimal(Coinbase::WEI_PER_ETHER)
      else
        atomic_amount
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

    # Returns a new Asset object. Do not use this method. Instead, use the Asset constants defined in
    # the Coinbase module.
    # @param network_id [Symbol] The ID of the Network to which the Asset belongs
    # @param asset_id [Symbol] The Asset ID
    # @param display_name [String] The Asset's display name
    # @param address_id [String] (Optional) The Asset's address ID, if one exists
    def initialize(network_id:, asset_id:, display_name:, address_id: nil)
      @network_id = network_id
      @asset_id = asset_id
      @display_name = display_name
      @address_id = address_id
    end

    attr_reader :network_id, :asset_id, :display_name, :address_id
  end
end
