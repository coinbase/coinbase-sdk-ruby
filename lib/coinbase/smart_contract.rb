# frozen_string_literal: true

module Coinbase
  # A representation of a SmartContract on the blockchain.
  class SmartContract
    # Returns a list of ContractEvents for the provided network, contract, and event details.
    # @param network_id [Symbol] The network ID
    # @param protocol_name [String] The protocol name
    # @param contract_address [String] The contract address
    # @param contract_name [String] The contract name
    # @param event_name [String] The event name
    # @param from_block_height [Integer] The start block height
    # @param to_block_height [Integer] The end block height
    # @return [Enumerable<Coinbase::ContractEvent>] The contract events
    def self.list_events(
      network_id:,
      protocol_name:,
      contract_address:,
      contract_name:,
      event_name:,
      from_block_height:,
      to_block_height:
    )
      Coinbase::Pagination.enumerate(
        lambda { |page|
          list_events_page(
            network_id,
            protocol_name,
            contract_address,
            contract_name,
            event_name,
            from_block_height,
            to_block_height,
            page
          )
        }
      ) do |contract_event|
        Coinbase::ContractEvent.new(contract_event)
      end
    end

    # Creates a new ERC20 token contract, that can subsequently be deployed to
    # the blockchain.
    # @param address_id [String] The address ID of deployer
    # @param wallet_id [String] The wallet ID of the deployer
    # @param name [String] The name of the token
    # @param symbol [String] The symbol of the token
    # @param total_supply [String] The total supply of the token, denominate in whole units.
    # @return [SmartContract] The new ERC20 Token SmartContract object
    def self.create_token_contract(
      address_id:,
      wallet_id:,
      name:,
      symbol:,
      total_supply:
    )
      contract = Coinbase.call_api do
        smart_contracts_api.create_smart_contract(
          wallet_id,
          address_id,
          {
            type: Coinbase::Client::SmartContractType::ERC20,
            options: Coinbase::Client::TokenContractOptions.new(
              name: name,
              symbol: symbol,
              total_supply: BigDecimal(total_supply).to_i.to_s
            ).to_body
          }
        )
      end

      new(contract)
    end

    def self.contract_events_api
      Coinbase::Client::ContractEventsApi.new(Coinbase.configuration.api_client)
    end
    private_class_method :contract_events_api

    def self.smart_contracts_api
      Coinbase::Client::SmartContractsApi.new(Coinbase.configuration.api_client)
    end
    private_class_method :smart_contracts_api

    def self.list_events_page(
      network_id,
      protocol_name,
      contract_address,
      contract_name,
      event_name,
      from_block_height,
      to_block_height,
      page
    )
      contract_events_api.list_contract_events(
        Coinbase.normalize_network(network_id),
        protocol_name,
        contract_address,
        contract_name,
        event_name,
        from_block_height,
        to_block_height,
        { next_page: page }
      )
    end
    private_class_method :list_events_page

    # Returns a new SmartContract object.
    # @param model [Coinbase::Client::SmartContract] The underlying SmartContract object
    def initialize(model)
      raise unless model.is_a?(Coinbase::Client::SmartContract)

      @model = model
    end

    # Returns the SmartContract ID.
    # NOTE: This is not the contract address and is primarily used before
    # the contract is deployed.
    # @return [String] The SmartContract ID
    def id
      @model.smart_contract_id
    end

    # Returns the Network of the SmartContract.
    # @return [Coinbase::Network] The Network
    def network
      @network ||= Coinbase::Network.from_id(@model.network_id)
    end

    # Returns the contract address of the SmartContract.
    # @return [String] The contract address
    def contract_address
      @model.contract_address
    end

    # Returns the address of the deployer of the SmartContract.
    # @return [String] The deployer address
    def deployer_address
      @model.deployer_address
    end

    # Returns the ABI of the Smart Contract.
    # @return [Array<Hash>] The ABI
    def abi
      JSON.parse(@model.abi)
    end

    # Returns the ID of the wallet that deployed the SmartContract.
    # @return [String] The wallet ID
    def wallet_id
      @model.wallet_id
    end

    # Returns the type of the SmartContract.
    # @return [Coinbase::Client::SmartContractType] The SmartContract type
    def type
      @model.type
    end

    # Returns the options of the SmartContract.
    # @return [Coinbase::Client::SmartContractOptions] The SmartContract options
    def options
      @model.options
    end

    # Returns the transaction.
    # @return [Coinbase::Transaction] The SmartContracy deployment transaction
    def transaction
      @transaction ||= Coinbase::Transaction.new(@model.transaction)
    end

    # Returns the status of the SmartContract.
    # @return [String] The status
    def status
      transaction.status
    end

    # Signs the SmartContract deployment transaction with the given key.
    # This is required before broadcasting the SmartContract.
    # @param key [Eth::Key] The key to sign the SmartContract with
    # @return [SmartContract] The SmartContract object
    # @raise [RuntimeError] If the key is not an Eth::Key
    # @raise [Coinbase::AlreadySignedError] If the SmartContract has already been signed
    def sign(key)
      raise unless key.is_a?(Eth::Key)

      transaction.sign(key)
    end

    # Deploys the signed SmartContract to the blockchain.
    # @return [SmartContract] The SmartContract object
    # @raise [Coinbase::TransactionNotSignedError] If the SmartContract has not been signed
    def deploy!
      raise TransactionNotSignedError unless transaction.signed?

      @model = Coinbase.call_api do
        smart_contracts_api.deploy_smart_contract(
          wallet_id,
          deployer_address,
          id,
          { signed_payload: transaction.signature }
        )
      end

      @transaction = Coinbase::Transaction.new(@model.transaction)

      self
    end

    # Reloads the Smart Contract model with the latest version from the server side.
    # @return [SmartContract] The most recent version of Smart Contract from the server
    def reload
      @model = Coinbase.call_api do
        smart_contracts_api.get_smart_contract(
          wallet_id,
          deployer_address,
          id
        )
      end

      @transaction = Coinbase::Transaction.new(@model.transaction)

      self
    end

    # Waits until the Smart Contract deployment is signed or failed by polling the server at the given interval.
    # @param interval_seconds [Integer] The interval at which to poll the server, in seconds
    # @param timeout_seconds [Integer] The maximum amount of time to wait for the Smart Contract,
    # deployment to land on-chain, in seconds
    # @return [SmartContract] The completed Smart Contract object
    # @raise [Timeout::Error] if the Contract Invocation takes longer than the given timeout
    def wait!(interval_seconds = 0.2, timeout_seconds = 20)
      start_time = Time.now

      loop do
        reload

        return self if transaction.terminal_state?

        if Time.now - start_time > timeout_seconds
          raise Timeout::Error,
                'SmartContract deployment timed out. Try waiting again.'
        end

        self.sleep interval_seconds
      end

      self
    end

    # Same as to_s.
    # @return [String] a string representation of the SmartContract
    def inspect
      to_s
    end

    # Returns a string representation of the SmartContract.
    # @return [String] a string representation of the SmartContract
    def to_s
      Coinbase.pretty_print_object(
        self.class,
        network: network.id,
        contract_address: contract_address,
        deployer_address: deployer_address,
        type: type,
        status: status,
        options: Coinbase.pretty_print_object('Options', **options)
      )
    end

    private

    def smart_contracts_api
      @smart_contracts_api ||= Coinbase::Client::SmartContractsApi.new(Coinbase.configuration.api_client)
    end
  end
end
