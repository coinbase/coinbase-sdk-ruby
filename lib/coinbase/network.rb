# frozen_string_literal: true

module Coinbase
  # A blockchain network.
  class Network
    attr_reader :chain_id

    # Returns a new Network object.
    #
    # @param network_id [Symbol] The Network ID
    # @param display_name [String] The Network's display name
    # @param protocol_family [String] The protocol family to which the Network belongs
    #   (e.g., "evm")
    # @param is_testnet [Boolean] Whether the Network is a testnet
    # @param native_asset_id [String] The ID of the Network's native Asset
    # @param chain_id [Integer] (Optional) The Chain ID of the Network
    def initialize(network_id:, display_name:, protocol_family:, is_testnet:, native_asset_id:, chain_id:)
      @network_id = network_id
      @display_name = display_name
      @protocol_family = protocol_family
      @is_testnet = is_testnet
      @native_asset_id = native_asset_id
      @chain_id = chain_id
    end
  end
end
