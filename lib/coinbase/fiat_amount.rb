# frozen_string_literal: true

module Coinbase
  # A representation of a FiatAmount that includes the amount and fiat.
  class FiatAmount
    # Converts a Coinbase::Client::FiatAmount model to a Coinbase::FiatAmount
    # @param model [Coinbase::Client::FiatAmount] The crypto amount from the API.
    # @return [FiatAmount] The converted FiatAmount object.
    def self.from_model(model)
      unless model.is_a?(Coinbase::Client::FiatAmount)
        raise ArgumentError,
              'model must be a Coinbase::Client::FiatAmount'
      end

      new(amount: model.amount, currency: model.currency)
    end

    # Returns a new FiatAmount object.
    # @param amount [BigDecimal, String] The amount of the Fiat Currency
    # @param currency [Symbol, String] The currency of the Fiat Amount
    def initialize(amount:, currency:)
      @amount = BigDecimal(amount)
      @currency = Coinbase.to_sym(currency)
    end

    attr_reader :amount, :currency

    # Returns a string representation of the FiatAmount.
    # @return [String] a string representation of the FiatAmount
    def to_s
      Coinbase.pretty_print_object(self.class, amount: amount.to_s('F'), currency: currency)
    end

    # Same as to_s.
    # @return [String] a string representation of the FiatAmount
    def inspect
      to_s
    end
  end
end
