# frozen_string_literal: true

module Coinbase
  # A blockchain network.
  class Network
    attr_reader :chain_id

    # Returns a new Network object. Do not use this method directly. Instead, use the Network constants defined in
    # the Coinbase module.
    # @param network_id [Symbol] The Network ID
    # @param display_name [String] The Network's display name
    # @param protocol_family [String] The protocol family to which the Network belongs
    #   (e.g., "evm")
    # @param is_testnet [Boolean] Whether the Network is a testnet
    # @param assets [Array<Asset>] The Assets supported by the Network
    # @param native_asset_id [String] The ID of the Network's native Asset
    # @param chain_id [Integer] The Chain ID of the Network
    def initialize(network_id:, display_name:, protocol_family:, is_testnet:, assets:, native_asset_id:, chain_id:)
      @network_id = network_id
      @display_name = display_name
      @protocol_family = protocol_family
      @is_testnet = is_testnet
      @chain_id = chain_id

      @asset_map = {}
      assets.each do |asset|
        @asset_map[asset.asset_id] = asset
      end

      raise ArgumentError, 'Native Asset not found' unless @asset_map.key?(native_asset_id)

      @native_asset = @asset_map[native_asset_id]
    end

    # Lists the Assets supported by the Network.
    #
    # @return [Array<Asset>] The Assets supported by the Network
    def list_assets
      @asset_map.values
    end

    # Gets the Asset with the given ID.
    #
    # @param asset_id [Symbol] The ID of the Asset
    # @return [Asset] The Asset with the given ID
    def get_asset(asset_id)
      @asset_map[asset_id]
    end

    # Gets the native Asset of the Network.
    #
    # @return [Asset] The native Asset of the Network
    attr_reader :native_asset
  end
end
