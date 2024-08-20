# frozen_string_literal: true

module Coinbase
  # A representation of an Asset.
  class Asset
    class << self
      # Returns the primary denomination for the provided Asset ID.
      # For assets with multiple denominations, e.g. eth can also be denominated in wei and gwei,
      # this method will return the primary denomination.
      # e.g. eth.
      # @param asset_id [Symbol] The Asset ID
      # @return [Symbol] The primary denomination for the Asset ID
      def primary_denomination(asset_id)
        return :eth if %i[wei gwei].include?(asset_id)

        asset_id
      end

      def from_model(asset_model, asset_id: nil)
        raise unless asset_model.is_a?(Coinbase::Client::Asset)

        decimals = asset_model.decimals

        # Handle the non-primary denomination case at the asset level.
        # TODO: Push this logic down to the backend.
        if asset_id && Coinbase.to_sym(asset_id) != Coinbase.to_sym(asset_model.asset_id)
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
          network: Coinbase.to_sym(asset_model.network_id),
          asset_id: asset_id || Coinbase.to_sym(asset_model.asset_id),
          address_id: asset_model.contract_address,
          decimals: decimals
        )
      end

      # Fetches the Asset with the provided Asset ID.
      # @param network [Coinbase::Network, Symbol] The Network or Network ID
      # @param asset_id [Symbol] The Asset ID
      # @return [Coinbase::Asset] The Asset
      def fetch(network, asset_id)
        network = Coinbase::Network.from_id(network)

        asset_model = Coinbase.call_api do
          assets_api.get_asset(
            network.normalized_id,
            primary_denomination(asset_id).to_s
          )
        end

        from_model(asset_model, asset_id: asset_id)
      end

      private

      def assets_api
        Coinbase::Client::AssetsApi.new(Coinbase.configuration.api_client)
      end
    end

    # Returns a new Asset object. Do not use this method. Instead, use the Asset constants defined in
    # the Coinbase module.
    # @param network [Symbol] The Network or Network ID to which the Asset belongs
    # @param asset_id [Symbol] The Asset ID
    # @param address_id [String] (Optional) The Asset's address ID, if one exists
    # @param decimals [Integer] (Optional) The number of decimal places the Asset uses
    def initialize(network:, asset_id:, decimals:, address_id: nil)
      @network = Coinbase::Network.from_id(network)
      @asset_id = asset_id
      @address_id = address_id
      @decimals = decimals
    end

    attr_reader :network, :asset_id, :address_id, :decimals

    # Converts the amount of the Asset from atomic to whole units.
    # @param atomic_amount [Integer, Float, BigDecimal] The atomic amount to convert to whole units.
    # @return [BigDecimal] The amount in whole units
    def from_atomic_amount(atomic_amount)
      BigDecimal(atomic_amount) / BigDecimal(10).power(decimals)
    end

    # Converts the amount of the Asset from whole to atomic units.
    # @param whole_amount [Integer, Float, BigDecimal] The whole amount to convert to atomic units.
    # @return [BigDecimal] The amount in atomic units
    def to_atomic_amount(whole_amount)
      whole_amount * BigDecimal(10).power(decimals)
    end

    # Returns the primary denomination for the Asset.
    # For `gwei` and `wei` the primary denomination is `eth`.
    # For all other assets, the primary denomination is the same asset ID.
    # @return [Symbol] The primary denomination for the Asset
    def primary_denomination
      self.class.primary_denomination(asset_id)
    end

    # Returns a string representation of the Asset.
    # @return [String] a string representation of the Asset
    def to_s
      "Coinbase::Asset{network_id: '#{network.id}', asset_id: '#{asset_id}', decimals: '#{decimals}'" \
        "#{address_id.nil? ? '' : ", address_id: '#{address_id}'"}}"
    end

    # Same as to_s.
    # @return [String] a string representation of the Balance
    def inspect
      to_s
    end
  end
end
