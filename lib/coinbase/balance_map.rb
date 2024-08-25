# frozen_string_literal: true

require 'bigdecimal'

module Coinbase
  # A convenience class for printing out Asset balances in a human-readable format.
  class BalanceMap < Hash
    class << self
      # Converts a list of Coinbase::Client::Balance models to a Coinbase::BalanceMap.
      # @param balances [Array<Coinbase::Client::Balance>] The list of balances fetched from the API.
      # @return [BalanceMap] The converted BalanceMap object.
      def from_balances(balances)
        BalanceMap.new.tap do |balance_map|
          balances.each do |balance_model|
            balance = Coinbase::Balance.from_model(balance_model)

            balance_map.add(balance)
          end
        end
      end
    end

    # Adds a balance to the map.
    # @param balance [Coinbase::Balance] The balance to add to the map.
    def add(balance)
      raise ArgumentError, 'balance must be a Coinbase::Balance' unless balance.is_a?(Coinbase::Balance)

      self[balance.asset_id] = balance.amount
    end

    # Returns a string representation of the balance map.
    # @return [String] The string representation of the balance map
    def to_s
      to_string
    end

    # Returns a string representation of the balance map.
    # @return [String] The string representation of the balance map
    def inspect
      to_string
    end

    private

    # Returns a string representation of the balance map.
    # @return [String] The string representation of the balance map
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
