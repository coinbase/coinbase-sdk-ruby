# frozen_string_literal: true

module Coinbase
  # A blockchain network.
  class Network
    # Returns the Network object for the given ID, if supported.
    # @param network_id [Symbol, String] The ID of the network
    # @return [Network] The network object
    def self.from_id(network_id)
      return network_id if network_id.is_a?(Network)

      network = NETWORK_MAP.fetch(Coinbase.to_sym(network_id), nil)

      return network unless network.nil?

      raise NetworkUnsupportedError, network_id
    end

    # Constructs a new Network object. Do not use this method directly. Instead, use the Network constants defined in
    # the Coinbase module.
    # @param id [Symbol, String] The Network ID
    # @return [Network] The new Network object
    def initialize(id)
      @id = ::Coinbase.to_sym(id)
    end

    # Returns the equality of the Network object with another Network object by ID.
    # @param other [Coinbase::Network] The network object to compare
    # @return [Boolean] Whether the Network objects are equal
    def ==(other)
      return false unless other.is_a?(Network)

      id == other.id
    end

    attr_reader :id

    def normalized_id
      id.to_s.gsub('_', '-')
    end

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

    # The address path prefix of the Network.
    # @return [String] The address path prefix of the Network
    # @example
    #   network.address_path_prefix #=> "m/44'/60'/0'/0"
    def address_path_prefix
      model.address_path_prefix
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
