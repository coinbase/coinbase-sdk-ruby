# frozen_string_literal: true

module Coinbase
  # A representation of a staking operation (stake, unstake, claim rewards, etc). It
  # may have multiple steps with some being transactions to sign, and others to wait.
  # @attr_reader [Array<Coinbase::Transaction>] transactions The list of current
  # @attr_reader [Symbol] status The status of the operation
  # @attr_reader [String] error The error message if the operation failed
  #   transactions associated with the operation
  class StakingOperation
    attr_reader :transactions, :status, :error

    # Returns all StakingOperations.
    # @return [Enumerable<Coinbase::StakingOperation>] The staking operations
    def self.list
      Coinbase::Pagination.enumerate(
        ->(page) { Coinbase.call_api { Coinbase::Client::StakingOperation.list(page: page) } }
      ) do |staking_operation|
        new(staking_operation)
      end
    end

    # Returns the StakingOperation with the provided ID.
    # @param id [String] The ID of the StakingOperation
    # @return [Coinbase::StakingOperation] The staking operation
    def self.fetch(id)
      new(load_from_sever(id))
    end

    def self.load_from_sever(id)
      Coinbase.call_api { Coinbase::Client::StakingOperation.fetch(id) }
    end

    # Returns a new StakingOperation object.
    # @param model [Coinbase::Client::StakingOperation] The underlying StakingOperation object
    def initialize(model)
      from_model(model)
    end

    # Signs the Open Transactions with the provided key
    # @param key [Eth::Key] The key to sign the transactions with
    def sign(key)
      transactions.each do |transaction|
        transaction.sign(key) unless transaction.signed?
      end
    end

    # Reloads the staking_operation from the service
    # @return [Coinbase::StakingOperation] The updated staking operation
    def reload
      from_model(self.class.load_from_sever(@model.id))
    end

    # Fetches the presigned exit transactions for the staking operation
    # @return [Array<string>] The list of presigned exit transaction messages
    def presigned_exit_transactions
      return [] unless @model.metadata

      @model.metadata['presigned_exit_transactions']
    end

    private

    def from_model(model)
      @model = model

      @status = model.status
      @transactions = model.transactions.map do |transaction_model|
        Transaction.new(transaction_model)
      end
    end
  end
end
