# frozen_string_literal: true

require 'bigdecimal'

module Coinbase
  # A convenience class for printing out Asset balances in a human-readable format.
  class BalanceMap < Hash
    # Returns a new BalanceMap object.
    # @param hash [Map<Symbol, BigDecimal>] The hash to initialize with
    def initialize(hash = {})
      super()
      hash.each do |key, value|
        self[key] = value
      end
    end

    # Returns a string representation of the balance map.
    # @return [String] The string representation of the balance
    def to_s
      to_string
    end

    # Returns a string representation of the balance map.
    # @return [String] The string representation of the balance
    def inspect
      to_string
    end

    private

    # Returns a string representation of the balance.
    # @return [String] The string representation of the balance
    def to_string
      result = {}

      each do |asset_id, balance|
        # Convert to floating-point number (not scientific notation)
        str = balance.to_s('F')

        str = balance.to_i.to_s if balance.frac.zero?

        result[asset_id] = str
      end

      result.to_s
    end
  end
end
