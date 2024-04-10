module Coinbase

  # A blockchain network
  class Network
    attr_reader :network_id, :display_name, :protocol_family, :is_testnet, :native_asset_id

    # Returns a new Network object.
    #
    # @param network_id [Symbol] The Network ID
    # @param display_name [String] The Network's display name
    # @param protocol_family [String] The protocol family to which the Network belongs
    #   (e.g., "evm")
    # @param is_testnet [Boolean] Whether the Network is a testnet
    # @param native_asset_id [String] The ID of the Network's native Asset
    def initialize(network_id:, display_name:, protocol_family:, is_testnet:, native_asset_id:)
      @network_id = network_id
      @display_name = display_name
      @protocol_family = protocol_family
      @is_testnet = is_testnet
      @native_asset_id = native_asset_id
    end

    # Returns the Asset object for the given Asset ID.
    #
    # @param asset_id [Symbol] The ID of the Asset to retrieve
    # @return [Asset] The Asset object
    def get_asset(asset_id)
      MockData::DataProvider.instance.get_asset(@network_id, asset_id)
    end

    # Lists the Assets for the Network.
    #
    # @return [Array<Asset>] The list of Assets
    def list_assets
      MockData::DataProvider.instance.list_assets(@network_id)
    end

    # Returns the resource name.
    # @return [String] The resource name
    def resource_name
      "networks/#{@network_id}"
    end
  end
end
