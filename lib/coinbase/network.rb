# frozen_string_literal: true

module Coinbase
  # A blockchain network.
  class Network
    # Constructs a new Network object. Do not use this method directly. Instead, use the Network constants defined in
    # the Coinbase module.
    # @param id [Symbol, String] The Network ID
    # @return [Network] The new Network object
    def initialize(id)
      @id = ::Coinbase.to_sym(id)
    end

    attr_reader :id

    # The Chain ID of the Network.
    # @return [Integer] The Chain ID of the Network
    # @example
    #   network.chain_id #=> 84_532
    def chain_id
      model.chain_id
    end

    # Whether the Network is a testnet.
    # @return [Boolean] Whether the Network is a testnet
    # @example
    #   network.testnet? #=> true
    def testnet?
      model.is_testnet
    end

    # The display name of the Network.
    # @return [String] The display name of the Network
    # @example
    #  network.display_name #=> "Base Sepolia"
    def display_name
      model.display_name
    end

    # The protocol family to which the Network belongs. Example: `evm`.
    # @return [String] The protocol family to which the Network belongs.
    # @example
    #  network.protocol_family #=> "evm"
    def protocol_family
      model.protocol_family
    end

    # Gets the Asset with the given ID.
    # @param asset_id [Symbol] The ID of the Asset
    # @return [Asset] The Asset with the given ID
    def get_asset(asset_id)
      Asset.fetch(@id, asset_id)
    end

    # Gets the native Asset of the Network.
    # @return [Asset] The native Asset of the Network
    def native_asset
      @native_asset ||= Coinbase::Asset.from_model(model.native_asset)
    end

    def to_s
      details = { id: id }

      # Only include optional details if the model is already fetched.
      unless @model.nil?
        Coinbase::Client::Network.attribute_map.each_key do |attr|
          details[attr] = @model.send(attr)
        end
      end

      Coinbase.pretty_print_object(self.class, **details)
    end

    def inspect
      to_s
    end

    private

    def networks_api
      @networks_api ||= Coinbase::Client::NetworksApi.new(Coinbase.configuration.api_client)
    end

    def model
      @model ||= Coinbase.call_api do
        networks_api.get_network(Coinbase.normalize_network(id))
      end
    end
  end
end
