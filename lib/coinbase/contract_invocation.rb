# frozen_string_literal: true

require 'bigdecimal'

module Coinbase
  # A representation of a Contract Invocation.
  class ContractInvocation
    class << self
      # Creates a new ContractInvocation object.
      # @param address_id [String] The Address ID of the signing Address
      # @param wallet_id [String] The Wallet ID associated with the signing Address
      # @param contract_address [String] The contract address
      # @param abi [Array<Hash>] The contract ABI
      # @param method [String] The contract method
      # @param amount [Integer, Float, BigDecimal] The amount of the native Asset
      #   to send to a payable contract method.
      # @param asset_id [Symbol] The ID of the Asset to send to a payable contract method.
      #   The Asset must be a denomination of the native Asset. For Ethereum, :eth, :gwei, and :wei are supported.
      # @param network [Coinbase::Network, Symbol] The Network or Network ID of the Asset
      # @param args [Hash] The arguments to pass to the contract method.
      #   The keys should be the argument names, and the values should be the argument values.
      # @return [ContractInvocation] The new Contract Invocation object
      # @raise [Coinbase::ApiError] If the request to create the Contract Invocation fails
      def create(
        address_id:,
        wallet_id:,
        contract_address:,
        abi:,
        method:,
        amount:,
        asset_id:,
        network:,
        args: {}
      )
        atomic_amount = nil

        if amount && asset_id && network
          network = Coinbase::Network.from_id(network)
          asset = network.get_asset(asset_id)
          atomic_amount = asset.to_atomic_amount(amount).to_i_to_s
        end

        # If the contract address is a SmartContract object, get the contract address from it.
        if contract_address.is_a?(Coinbase::SmartContract)
          contract_address = contract_address.contract_address
        end

        model = Coinbase.call_api do
          contract_invocation_api.create_contract_invocation(
            wallet_id,
            address_id,
            contract_address: contract_address,
            abi: abi.to_json,
            method: method,
            args: args.to_json,
            amount: atomic_amount
          )
        end

        new(model)
      end

      # Enumerates the payload signatures for a given address belonging to a wallet.
      # The result is an enumerator that lazily fetches from the server, and can be iterated over,
      # converted an array, etc...
      # @return [Enumerable<Coinbase::ContractInvocation>] Enumerator that returns payload signatures
      def list(wallet_id:, address_id:)
        Coinbase::Pagination.enumerate(
          ->(page) { fetch_page(wallet_id, address_id, page) }
        ) do |contract_invocation|
          new(contract_invocation)
        end
      end

      private

      def contract_invocation_api
        Coinbase::Client::ContractInvocationsApi.new(Coinbase.configuration.api_client)
      end

      def fetch_page(wallet_id, address_id, page)
        contract_invocation_api.list_contract_invocations(
          wallet_id,
          address_id,
          limit: DEFAULT_PAGE_LIMIT,
          page: page
        )
      end
    end

    # Returns a new ContractInvocation object. Do not use this method directly.
    # Instead use Coinbase::ContractInvocation.create.
    # @param model [Coinbase::Client::ContractInvocation] The underlying Contract Invocation obejct
    def initialize(model)
      raise unless model.is_a?(Coinbase::Client::ContractInvocation)

      @model = model
    end

    # Returns the Contract Invocation ID.
    # @return [String] The Contract Invocation ID
    def id
      @model.contract_invocation_id
    end

    # Returns the Wallet ID of the Contract Invocation.
    # @return [String] The Wallet ID
    def wallet_id
      @model.wallet_id
    end

    # Returns the Address ID of the Contract Invocation.
    # @return [String] The Address ID
    def address_id
      @model.address_id
    end

    # Returns the Network of the Contract Invocation.
    # @return [Coinbase::Network] The Network
    def network
      @network ||= Coinbase::Network.from_id(@model.network_id)
    end

    # Returns the Contract Address of the Contract Invocation.
    # @return [String] The Contract Address
    def contract_address
      @model.contract_address
    end

    # Returns the ABI of the Contract Invocation.
    # @return [Array<Hash>] The ABI
    def abi
      JSON.parse(@model.abi)
    end

    # Returns the method of the Contract Invocation.
    # @return [String] The method
    def method
      @model.method
    end

    # Returns the arguments of the Contract Invocation.
    # @return [Hash] The arguments
    def args
      JSON.parse(@model.args).transform_keys(&:to_sym)
    end

    # Returns the amount of the native asset sent to a payable contract method, if applicable.
    # @return [BigDecimal] The amount in atomic units of the native asset
    def amount
      BigDecimal(@model.amount)
    end

    # Returns the transaction.
    # @return [Coinbase::Transaction] The Transfer transaction
    def transaction
      @transaction ||= Coinbase::Transaction.new(@model.transaction)
    end

    # Returns the status of the Contract Invocation.
    # @return [String] The status
    def status
      transaction.status
    end

    # Signs the Contract Invocation transaction with the given key.
    # This is required before broadcasting the Contract Invocation when not using
    # a Server-Signer.
    # @param key [Eth::Key] The key to sign the ContractInvocation with
    # @raise [RuntimeError] If the key is not an Eth::Key
    # @return [ContractInvocation] The ContractInvocation object
    def sign(key)
      raise unless key.is_a?(Eth::Key)

      transaction.sign(key)

      self
    end

    # Broadcasts the ContractInvocation to the Network.
    # @raise [RuntimeError] If the ContractInvocation is not signed
    # @return [ContractInvocation] The ContractInvocation object
    def broadcast!
      raise TransactionNotSignedError unless transaction.signed?

      @model = Coinbase.call_api do
        contract_invocation_api.broadcast_contract_invocation(
          wallet_id,
          address_id,
          id,
          { signed_payload: transaction.signature }
        )
      end

      @transaction = Coinbase::Transaction.new(@model.transaction)

      self
    end

    # # Reload reloads the Contract Invocation model with the latest version from the server side.
    # @return [ContractInvocation] The most recent version of Contract Invocation from the server
    def reload
      @model = Coinbase.call_api do
        contract_invocation_api.get_contract_invocation(wallet_id, address_id, id)
      end

      @transaction = Coinbase::Transaction.new(@model.transaction)

      self
    end

    # Waits until the Contract Invocation is signed or failed by polling the server at the given interval. Raises a
    # Timeout::Error if the Contract Invocation takes longer than the given timeout.
    # @param interval_seconds [Integer] The interval at which to poll the server, in seconds
    # @param timeout_seconds [Integer] The maximum amount of time to wait for the Contract Invocation to be signed,
    # in seconds.
    # @return [ContractInvocation] The completed Contract Invocation object
    def wait!(interval_seconds = 0.2, timeout_seconds = 20)
      start_time = Time.now

      loop do
        reload

        return self if transaction.terminal_state?

        raise Timeout::Error, 'Contract Invocation timed out' if Time.now - start_time > timeout_seconds

        self.sleep interval_seconds
      end

      self
    end

    # Returns a String representation of the Contract Invocation.
    # @return [String] a String representation of the Contract Invocation
    def to_s
      Coinbase.pretty_print_object(
        self.class,
        id: id,
        wallet_id: wallet_id,
        address_id: address_id,
        network_id: network.id,
        status: status,
        abi: abi.to_json,
        method: method,
        args: args.to_json,
        transaction_hash: transaction.transaction_hash,
        transaction_link: transaction.transaction_link
      )
    end

    # Same as to_s.
    # @return [String] a String representation of the ContractInvocation
    def inspect
      to_s
    end

    private

    def contract_invocation_api
      @contract_invocation_api ||= Coinbase::Client::ContractInvocationsApi.new(Coinbase.configuration.api_client)
    end
  end
end
