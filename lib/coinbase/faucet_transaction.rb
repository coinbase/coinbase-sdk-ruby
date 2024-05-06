# frozen_string_literal: true

module Coinbase
  # A representation of a transaction from a faucet.
  # a user-controlled Wallet to another address. The fee is assumed to be paid
  # in the native Asset of the Network. Transfers should be created through Wallet#transfer or
  # Address#transfer.
  class FaucetTransaction
    # Returns a new FaucetTransaction object. Do not use this method directly - instead, use Address#faucet.
    # @param model [Coinbase::Client::FaucetTransaction] The underlying FaucetTransaction object
    def initialize(model)
      @model = model
    end

    attr_reader :model

    # Returns the transaction hash.
    # @return [String] The onchain transaction hash
    def transaction_hash
      model.transaction_hash
    end

    # Returns a String representation of the FaucetTransaction.
    # @return [String] a String representation of the FaucetTransaction
    def to_s
      "Coinbase::FaucetTransaction{transaction_hash: '#{transaction_hash}'}"
    end

    # Same as to_s.
    # @return [String] a String representation of the FaucetTransaction
    def inspect
      to_s
    end
  end
end
