# frozen_string_literal: true

module Coinbase
  # A representation of the intended recipient of an onchain interaction. For example, a simple
  # Transfer has a single destination, which is the address that will receive the transferred funds.
  # This class is used to handle the several different types that we can use as a destination,
  # namely a Coinbase::Wallet, a Coinbase::Address, a String.
  # This also ensures that the destination is valid for the network that is being interacted with.
  # If a Coinbase::Wallet is used, the default address of the wallet is used as the destination.
  # If a Coinbase::Address is used, the address ID is used as the destination.
  # If a String is used, the string is used as the destination.
  # If an existing Coinbase::Destination is used, the same address ID is used as the destination.
  class Destination
    # Returns a new Destination object.
    # @param model [Coinbase::Destination, Coinbase::Wallet, Coinbase::Address, String]
    #   The object which the `address_id` will be derived from.
    #   If the destination is a Destination, it uses the same address ID.
    #   If the destination is a Wallet, it uses the default Address of the Wallet.
    #   If the destination is an Address, it uses the Address's ID.
    #   If the destination is a String, it uses it as the Address ID.
    # @param network_id [Symbol] The ID of the Network to which the Destination belongs
    # @return [Destination] The Destination object
    def initialize(model, network:)
      network = Coinbase::Network.from_id(network)

      case model
      when Coinbase::Destination
        raise ArgumentError, 'destination network must match destination' unless model.network == network

        @address_id = model.address_id
        @network = model.network
      when Coinbase::Wallet
        raise ArgumentError, 'destination network must match wallet' unless model.network == network
        raise ArgumentError, 'destination wallet must have default address' if model.default_address.nil?

        @address_id = model.default_address.id
        @network = model.network
      when Coinbase::Address
        raise ArgumentError, 'destination network must match address' unless model.network == network

        @address_id = model.id
        @network = model.network
      when String
        @address_id = model
        @network = network
      else
        raise ArgumentError, "unsupported destination type: #{model.class}"
      end
    end

    attr_reader :address_id, :network
  end
end
