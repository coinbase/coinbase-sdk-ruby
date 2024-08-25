# frozen_string_literal: true

module Coinbase
  # A representation of a staking operation (stake, unstake, claim rewards, etc). It
  # may have multiple steps with some being transactions to sign, and others to wait.
  # @attr_reader [Array<Coinbase::Transaction>] transactions The list of current
  #   transactions associated with the operation.
  # @attr_reader [Symbol] status The status of the operation
  class StakingOperation
    attr_reader :transactions

    class << self
      # Builds an ephemeral staking operation this is intended to be called via an Address or Wallet.
      # @param amount [BigDecimal] The amount to stake, in the primary denomination of the asset
      # @param network [Coinbase::Network, Symbol] The Network or Network ID
      # @param asset_id [Symbol] The Asset ID
      # @param address_id [String] The Address ID
      # @param action [Symbol] The action to perform
      # @param mode [Symbol] The staking mode
      # @param options [Hash] Additional options
      # @return [Coinbase::StakingOperation] The staking operation
      def build(amount, network, asset_id, address_id, action, mode, options)
        network = Coinbase::Network.from_id(network)
        asset = network.get_asset(asset_id)

        model = Coinbase.call_api do
          stake_api.build_staking_operation(
            {
              asset_id: asset.primary_denomination.to_s,
              address_id: address_id,
              action: action,
              network_id: Coinbase.normalize_network(network),
              options: {
                amount: asset.to_atomic_amount(amount).to_i.to_s,
                mode: mode
              }.merge(options)
            }
          )
        end

        new(model)
      end

      # Creates a persisted staking operation this is intended to be called via an Address or Wallet.
      # @param amount [BigDecimal] The amount to stake, in the primary denomination of the asset
      # @param network [Coinbase::Network, Symbol] The Network or Network ID
      # @param asset_id [Symbol] The Asset ID
      # @param address_id [String] The Address ID
      # @param wallet_id [String] The Wallet ID
      # @param action [Symbol] The action to perform
      # @param mode [Symbol] The staking mode
      # @param options [Hash] Additional options
      # @return [Coinbase::StakingOperation] The staking operation
      def create(amount, network, asset_id, address_id, wallet_id, action, mode, options)
        network = Coinbase::Network.from_id(network)
        asset = network.get_asset(asset_id)

        model = Coinbase.call_api do
          wallet_stake_api.create_staking_operation(
            wallet_id,
            address_id,
            {
              asset_id: asset.primary_denomination.to_s,
              address_id: address_id,
              action: action,
              network_id: Coinbase.normalize_network(network),
              options: {
                amount: asset.to_atomic_amount(amount).to_i.to_s,
                mode: mode
              }.merge(options)
            }
          )
        end

        new(model)
      end

      # Fetch the StakingOperation with the provided network, address and staking operation ID.
      # @param network [Coinbase::Network, Symbol] The Network or Network ID
      # @param address_id [Symbol] The Address ID
      # @param id [String] The ID of the StakingOperation
      # @param wallet_id [String] The optional Wallet ID
      # @return [Coinbase::StakingOperation] The staking operation
      def fetch(network, address_id, id, wallet_id: nil)
        network = Coinbase::Network.from_id(network)

        staking_operation_model = Coinbase.call_api do
          if wallet_id.nil?
            stake_api.get_external_staking_operation(network.id, address_id, id)
          else
            wallet_stake_api.get_staking_operation(wallet_id, address_id, id)
          end
        end

        new(staking_operation_model)
      end

      private

      def stake_api
        Coinbase::Client::StakeApi.new(Coinbase.configuration.api_client)
      end

      def wallet_stake_api
        Coinbase::Client::WalletStakeApi.new(Coinbase.configuration.api_client)
      end
    end

    # Returns a new StakingOperation object.
    # @param model [Coinbase::Client::StakingOperation] The underlying StakingOperation object
    def initialize(model)
      @model = model
      @transactions ||= []
      update_transactions(model.transactions)
    end

    # Returns the Staking Operation ID.
    # @return [String] The Staking Operation ID
    def id
      @model.id
    end

    # Returns the Network of the Staking Operation.
    # @return [Coinbase::Network] The Network
    def network
      @network ||= Coinbase::Network.from_id(@model.network_id)
    end

    # Returns the Address ID of the Staking Operation.
    # @return [String] The Address ID
    def address_id
      @model.address_id
    end

    # Returns the status of the Staking Operation.
    # @return [Symbol] The status
    def status
      @model.status
    end

    # Returns whether the Staking Operation is in a terminal state.
    # @return [Boolean] Whether the Staking Operation is in a terminal state
    def terminal_state?
      failed? || completed?
    end

    # Returns whether the Staking Operation is in a failed state.
    # @return [Boolean] Whether the Staking Operation is in a failed state
    def failed?
      status == 'failed'
    end

    # Returns whether the Staking Operation is in a complete state.
    # @return [Boolean] Whether the Staking Operation is in a complete state
    def completed?
      status == 'complete'
    end

    # Returns a String representation of the Staking Operation.
    # @return [String] a String representation of the Staking Operation
    def to_s
      Coinbase.pretty_print_object(
        self.class,
        id: id,
        status: status,
        network_id: network.id,
        address_id: address_id
      )
    end

    # Returns the Wallet ID of the Staking Operation.
    # @return [String] The Wallet ID
    def wallet_id
      @model.wallet_id
    end

    # Waits until the Staking Operation is completed or failed by polling its status at the given interval.
    # @param interval_seconds [Integer] The interval at which to poll, in seconds
    # @param timeout_seconds [Integer] The maximum amount of time
    #   to wait for the StakingOperation to complete, in seconds
    # @return [StakingOperation] The completed StakingOperation object
    # @raise [Timeout::Error] if the Staking Operation takes longer than the given timeout.
    def wait!(interval_seconds = 5, timeout_seconds = 3600)
      start_time = Time.now

      loop do
        reload

        # Wait for the Staking Operation to be in a terminal state.
        break if terminal_state?

        raise Timeout::Error, 'Staking Operation timed out' if Time.now - start_time > timeout_seconds

        self.sleep interval_seconds
      end

      self
    end

    # Complete helps the Staking Operation reach complete state, by polling its status at the given interval, signing
    # and broadcasting any available transaction.
    # @param key [Eth::Key] The key to sign the Staking Operation transactions with
    # @param interval_seconds [Integer] The interval at which to poll, in seconds
    # @param timeout_seconds [Integer] The maximum amount of time
    #   to wait for the StakingOperation to complete, in seconds
    # @return [StakingOperation] The completed StakingOperation object
    # @raise [Timeout::Error] if the Staking Operation takes longer than the given timeout.
    def complete(key, interval_seconds: 5, timeout_seconds: 600)
      start_time = Time.now

      loop do
        @transactions.each_with_index do |transaction, i|
          next if transaction.signed?

          transaction.sign(key)
          @model = Coinbase.call_api do
            wallet_stake_api.broadcast_staking_operation(
              wallet_id,
              address_id,
              id,
              { signed_payload: transaction.raw.hex, transaction_index: i }
            )
          end
        end

        return self if terminal_state?

        reload

        raise Timeout::Error, 'Staking Operation timed out' if Time.now - start_time > timeout_seconds

        sleep interval_seconds
      end
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
      @model = Coinbase.call_api do
        if wallet_id.nil?
          stake_api.get_external_staking_operation(network.id, address_id, id)
        else
          wallet_stake_api.get_staking_operation(wallet_id, address_id, id)
        end
      end

      update_transactions(@model.transactions)

      self
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

    # Broadcasts the Staking Operation transactions to the network
    # @return [Coinbase::StakingOperation]
    def broadcast!
      transactions.each_with_index do |transaction, i|
        raise TransactionNotSignedError unless transaction.signed?

        Coinbase.call_api do
          wallet_stake_api.broadcast_staking_operation(
            wallet_id,
            address_id,
            id,
            { signed_payload: transaction.raw.hex, transaction_index: i }
          )
        end
      end

      self
    end

    private

    def stake_api
      @stake_api ||= Coinbase::Client::StakeApi.new(Coinbase.configuration.api_client)
    end

    def wallet_stake_api
      @wallet_stake_api ||= Coinbase::Client::WalletStakeApi.new(Coinbase.configuration.api_client)
    end

    def update_transactions(transactions)
      # Only overwrite the transactions if the response is populated.
      return unless transactions && !transactions.empty?

      # Create a set of existing unsigned payloads to avoid duplicates.
      existing_unsigned_payloads = Set.new
      @transactions.each do |transaction|
        existing_unsigned_payloads.add(transaction.unsigned_payload)
      end

      # Add transactions that are not already in the transactions array.
      transactions.each do |transaction_model|
        unless existing_unsigned_payloads.include?(transaction_model.unsigned_payload)
          @transactions << Transaction.new(transaction_model)
        end
      end
    end
  end
end
