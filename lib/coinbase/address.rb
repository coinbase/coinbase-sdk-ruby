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

    # Returns a String representation of the Address.
    # @return [String] a String representation of the Address
    def to_s
      "Coinbase::Address{id: '#{id}', network_id: '#{network_id}'}"
    end

    # Same as to_s.
    # @return [String] a String representation of the Address
    def inspect
      to_s
    end

    # Returns true if the Address can sign transactions.
    # @return [Boolean] true if the Address can sign transactions
    def can_sign?
      false
    end

    def balances
      raise NotImplementedError, 'Must be implemented by subclass'
    end

    def balance(_asset_id)
      raise NotImplementedError, 'Must be implemented by subclass'
    end

    def faucet
      raise NotImplementedError, 'Must be implemented by subclass'
    end
  end
end
