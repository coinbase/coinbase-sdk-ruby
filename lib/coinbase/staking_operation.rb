# frozen_string_literal: true

module Coinbase
  # A representation of a staking operation (stake, unstake, claim rewards, etc). It
  # may have multiple steps with some being transactions to sign, and others to wait.
  # @attr_reader [Array<Coinbase::Transaction>] transactions The list of current
  #   transactions associated with the operation
  class StakingOperation
    attr_reader :transactions

    # Returns a new StakingOperation object.
    # @param model [Coinbase::Client::StakingOperation] The underlying StakingOperation object
    def initialize(model)
      @model = model

      @transactions = model.transactions.map do |transaction_model|
        Transaction.new(transaction_model)
      end
    end

    # Signs the Open Transactions with the provided key
    # @param key [Eth::Key] The key to sign the transactions with
    def sign(key)
      transactions.each do |transaction|
        transaction.sign(key) unless transaction.signed?
      end
    end
  end
end
