# frozen_string_literal: true

module Coinbase
  # A representation of a blockchain Address, which is a user-controlled account on a Network. Addresses are used to
  # send and receive Assets.
  # @attr_reader [Symbol] network_id The Network ID
  # @attr_reader [String] id The onchain Address ID
  class Address
    attr_reader :network_id, :id

    # Returns a new Address object.
    # @param network_id [Symbol] The Network ID
    # @param id [String] The onchain Address ID
    def initialize(network_id, id)
      @network_id = Coinbase.to_sym(network_id)
      @id = id
    end
  end
end
