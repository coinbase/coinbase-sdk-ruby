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

    # Returns the Faucet transaction.
    # @return [Coinbase::Transaction] The Faucet transaction
    def transaction
      @transaction ||= Coinbase::Transaction.new(@model.transaction)
    end

    # Returns the status of the Faucet transaction.
    # @return [Symbol] The status
    def status
      transaction.status
    end

    # Returns the transaction hash.
    # @return [String] The onchain transaction hash
    def transaction_hash
      transaction.transaction_hash
    end

    # Returns the link to the transaction on the blockchain explorer.
    # @return [String] The link to the transaction on the blockchain explorer
    def transaction_link
      transaction.transaction_link
    end

    # Returns the Network of the Transaction.
    # @return [Coinbase::Network] The Network
    def network
      transaction.network
    end

    # Waits until the FaucetTransaction is completed or failed by polling on the given interval.
    # @param interval_seconds [Integer] The interval at which to poll the Network, in seconds
    # @param timeout_seconds [Integer] The maximum amount of time to wait for the Transfer to complete, in seconds
    # @raise [Timeout::Error] if the FaucetTransaction takes longer than the given timeout
    # @return [Transfer] The completed Transfer object
    def wait!(interval_seconds = 0.2, timeout_seconds = 20)
      start_time = Time.now

      loop do
        reload

        return self if transaction.terminal_state?

        raise Timeout::Error, 'Faucet transaction timed out' if Time.now - start_time > timeout_seconds

        self.sleep interval_seconds
      end

      self
    end

    def reload
      @model = Coinbase.call_api do
        addresses_api.get_faucet_transaction(
          network.normalized_id,
          transaction.to_address_id,
          transaction_hash
        )
      end

      @transaction = Coinbase::Transaction.new(@model.transaction)

      self
    end

    # Returns a String representation of the FaucetTransaction.
    # @return [String] a String representation of the FaucetTransaction
    def to_s
      Coinbase.pretty_print_object(
        self.class,
        status: transaction.status,
        transaction_hash: transaction_hash,
        transaction_link: transaction_link
      )
    end

    # Same as to_s.
    # @return [String] a String representation of the FaucetTransaction
    def inspect
      to_s
    end

    private

    def addresses_api
      @addresses_api ||= Coinbase::Client::ExternalAddressesApi.new(Coinbase.configuration.api_client)
    end
  end
end
