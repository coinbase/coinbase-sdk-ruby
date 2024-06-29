# frozen_string_literal: true

module Coinbase
  # A representation of a blockchain Address that belongs to a Coinbase::Wallet.
  # Addresses are used to send and receive Assets, and should be created using
  # Wallet#create_address. Addresses require an Eth::Key to sign transaction data.
  class Destination
    # Returns a new Destination object. Do not use this method directly.
    # @param model [Coinbase::Destination, Coinbase::Wallet, Coinbase::Address, String] The underlying Destination object
    # @param network_id [Symbol] The ID of the Network to which the Destination belongs
    # @return [Destination] The Destination object
    def initialize(model, network_id: nil)
      case model
      when Coinbase::Destination
        raise ArgumentError, 'destination network must match desination' unless model.network_id == network_id

        @address_id = model.address_id
        @network_id = model.network_id
      when Coinbase::Wallet
        raise ArgumentError, 'destination network must match wallet' unless model.network_id == network_id

        @address_id = model.default_address.id
        @network_id = model.network_id
      when Coinbase::Address
        raise ArgumentError, 'destination network must match address' unless model.network_id == network_id

        @address_id = model.id
        @network_id = model.network_id
      when String
        @address_id = model
        @network_id = network_id
      else
        raise ArgumentError, "unsupported destination type: #{model.class}"
      end
    end

    attr_reader :address_id, :network_id
  end
end
