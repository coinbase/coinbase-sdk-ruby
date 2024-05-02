# frozen_string_literal: true

module Coinbase
  # A representation of a transaction from a faucet.
  # a user-controlled Wallet to another address. The fee is assumed to be paid
  # in the native Asset of the Network. Transfers should be created through Wallet#transfer or
  # Address#transfer.
  class FaucetTransaction
    def initialize(model)
      @model = model
    end

    attr_reader :model

    # Returns the transaction hash.
    # @return [String] The onchain transaction hash
    def transaction_hash
      model.transaction_hash
    end
  end
end
