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

    # Returns a new StakingOperation object.
    # @param model [Coinbase::Client::StakingOperation] The underlying StakingOperation object
    def initialize(model)
      from_model(model)
    end

    # Returns the StakingOperation with the provided ID.
    # @param id [String] The ID of the StakingOperation
    # @return [Coinbase::StakingOperation] The staking operation
    def self.fetch(network_id, address_id, staking_operation_id)
      new(load_from_server(network_id, address_id, staking_operation_id))
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
      from_model(self.class.load_from_server(@model.network_id, @model.address_id, @model.id))
    end

    # Fetches the presigned_voluntary exit messages for the staking operation
    # @return [Array<string>] The list of presigned exit transaction messages
    def signed_voluntary_exit_messages
      return [] unless @model.metadata

      signed_voluntary_exit_messages = []

      @model.metadata.each do |metadata|
        decoded_string = Base64.decode64(metadata.signed_voluntary_exit)
        signed_voluntary_exit_messages.push(decoded_string)
      end

      signed_voluntary_exit_messages
    end

    def self.stake_api
      Coinbase::Client::StakeApi.new(Coinbase.configuration.api_client)
    end

    private_class_method def self.load_from_server(network_id, address_id, staking_operation_id)
      stake_api.get_external_staking_operation(network_id, address_id, staking_operation_id)
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
