module Coinbase
  # A representation of an Asset.
  class Asset
    attr_reader :network_id, :asset_id, :display_name, :address_id

    # Returns a new Asset object.
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
  end
end
