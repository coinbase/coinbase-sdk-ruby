# frozen_string_literal: true

module Coinbase
  # A representation of a SmartContract on the blockchain.
  # rubocop:disable Metrics/ClassLength
  class SmartContract
    class << self
      # Returns a list of ContractEvents for the provided network, contract, and event details.
      # @param network_id [Symbol] The network ID
      # @param protocol_name [String] The protocol name
      # @param contract_address [String] The contract address
      # @param contract_name [String] The contract name
      # @param event_name [String] The event name
      # @param from_block_height [Integer] The start block height
      # @param to_block_height [Integer] The end block height
      # @return [Enumerable<Coinbase::ContractEvent>] The contract events
      def list_events(
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
      def create_token_contract(
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

      # Creates a new ERC721 token contract, that can subsequently be deployed to
      # the blockchain.
      # @param address_id [String] The address ID of deployer
      # @param wallet_id [String] The wallet ID of the deployer
      # @param name [String] The name of the token
      # @param symbol [String] The symbol of the token
      # @param base_uri [String] The base URI for the token metadata
      # @return [SmartContract] The new ERC721 Token SmartContract object
      def create_nft_contract(
        address_id:,
        wallet_id:,
        name:,
        symbol:,
        base_uri:
      )
        contract = Coinbase.call_api do
          smart_contracts_api.create_smart_contract(
            wallet_id,
            address_id,
            {
              type: Coinbase::Client::SmartContractType::ERC721,
              options: Coinbase::Client::NFTContractOptions.new(
                name: name,
                symbol: symbol,
                base_uri: base_uri
              ).to_body
            }
          )
        end

        new(contract)
      end

      # Creates a new ERC1155 multi-token contract, that can subsequently be deployed to
      # the blockchain.
      # @param address_id [String] The address ID of deployer
      # @param wallet_id [String] The wallet ID of the deployer
      # @param uri [String] The URI for the token metadata
      # @return [SmartContract] The new ERC1155 Multi-Token SmartContract object
      def create_multi_token_contract(
        address_id:,
        wallet_id:,
        uri:
      )
        contract = Coinbase.call_api do
          smart_contracts_api.create_smart_contract(
            wallet_id,
            address_id,
            {
              type: Coinbase::Client::SmartContractType::ERC1155,
              options: Coinbase::Client::MultiTokenContractOptions.new(
                uri: uri
              ).to_body
            }
          )
        end

        new(contract)
      end

      # Registers an externally deployed smart contract with the API.
      # @param contract_address [String] The address of the deployed contract
      # @param abi [Array, String] The ABI of the contract
      # @param network [Coinbase::Network, Symbol] The Network or Network ID the contract is deployed on
      # @param name [String, nil] The optional name of the contract
      def register(
        contract_address:,
        abi:,
        name: nil,
        network: Coinbase.default_network
      )
        network = Coinbase::Network.from_id(network)

        normalized_abi = normalize_abi(abi)

        smart_contract = Coinbase.call_api do
          smart_contracts_api.register_smart_contract(
            network.normalized_id,
            contract_address,
            register_smart_contract_request: {
              abi: normalized_abi.to_json,
              contract_name: name
            }.compact
          )
        end

        new(smart_contract)
      end

      # Reads data from a deployed smart contract.
      #
      # @param network [Coinbase::Network, Symbol] The Network or Network ID of the Asset
      # @param contract_address [String] The address of the deployed contract
      # @param method [String] The name of the method to call on the contract
      # @param abi [Array, nil] The ABI of the contract. If nil, the method will attempt to use a cached ABI
      # @param args [Hash] The arguments to pass to the contract method.
      #   The keys should be the argument names, and the values should be the argument values.
      # @return [Object] The result of the contract call, converted to an appropriate Ruby type
      # @raise [Coinbase::ApiError] If there's an error in the API call
      def read(
        contract_address:,
        method:,
        network: Coinbase.default_network,
        abi: nil,
        args: {}
      )
        network = Coinbase::Network.from_id(network)

        response = Coinbase.call_api do
          smart_contracts_api.read_contract(
            network.normalized_id,
            contract_address,
            {
              method: method,
              args: (args || {}).to_json,
              abi: abi&.to_json
            }.compact
          )
        end

        convert_solidity_value(response)
      end

      def list
        Coinbase::Pagination.enumerate(
          lambda { |page|
            smart_contracts_api.list_smart_contracts(page: page)
          }
        ) do |smart_contract|
          new(smart_contract)
        end
      end

      # Normalizes an ABI from a String or Array of Hashes to an Array of Hashes.
      # @param abi [String, Array] The ABI to normalize
      # @return [Array<Hash>] The normalized ABI
      # @raise [ArgumentError] If the ABI is not a valid JSON string or Array
      def normalize_abi(abi)
        return abi if abi.is_a?(Array)

        raise ArgumentError, 'ABI must be an Array or a JSON string' unless abi.is_a?(String)

        JSON.parse(abi)
      rescue JSON::ParserError
        raise ArgumentError, 'Invalid ABI JSON'
      end

      private

      # Converts a Solidity value to an appropriate Ruby type.
      #
      # @param solidity_value [Coinbase::Client::SolidityValue] The Solidity value to convert
      # @return [Object] The converted Ruby value
      # @raise [ArgumentError] If an unsupported Solidity type is encountered
      #
      # This method handles the following Solidity types:
      # - Integers (uint8, uint16, uint32, uint64, uint128, uint256, int8, int16, int32, int64, int128, int256)
      # - Address
      # - String
      # - Bytes (including fixed-size byte arrays)
      # - Boolean
      # - Array
      # - Tuple (converted to a Hash)
      #
      # For complex types like arrays and tuples, the method recursively converts nested values.
      def convert_solidity_value(solidity_value)
        return nil if solidity_value.nil?

        type = solidity_value.type
        value = solidity_value.value
        values = solidity_value.values

        case type
        when 'uint8', 'uint16', 'uint32', 'uint64', 'uint128', 'uint256',
         'int8', 'int16', 'int32', 'int64', 'int128', 'int256'
          value&.to_i
        when 'address', 'string', /^bytes/
          value
        when 'bool'
          if value.is_a?(String)
            value == 'true'
          else
            !value.nil?
          end
        when 'array'
          values ? values.map { |v| convert_solidity_value(v) } : []
        when 'tuple'
          if values
            result = {}
            values.each do |v|
              raise ArgumentError, 'Error: Tuple value without a name' unless v.respond_to?(:name)

              result[v.name] = convert_solidity_value(v)
            end
            result
          else
            {}
          end
        else
          raise ArgumentError, "Unsupported Solidity type: #{type}"
        end
      end

      def contract_events_api
        Coinbase::Client::ContractEventsApi.new(Coinbase.configuration.api_client)
      end

      def smart_contracts_api
        Coinbase::Client::SmartContractsApi.new(Coinbase.configuration.api_client)
      end

      def list_events_page(
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
    end

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

    # Returns the name of the SmartContract.
    # @return [String] The contract name
    def name
      @model.contract_name
    end

    # Returns the address of the deployer of the SmartContract, if deployed via CDP.
    # Returns nil for externally registered contracts.
    # @return [String, nil] The deployer address
    def deployer_address
      @model.deployer_address
    end

    # Returns the ABI of the Smart Contract.
    # @return [Array<Hash>] The ABI
    def abi
      JSON.parse(@model.abi)
    end

    # Returns the ID of the wallet that deployed the SmartContract, if deployed via CDP.
    # Returns nil for externally registered contracts.
    # @return [String] The wallet ID
    def wallet_id
      @model.wallet_id
    end

    # Returns the type of the SmartContract.
    # @return [Coinbase::Client::SmartContractType] The SmartContract type
    def type
      @model.type
    end

    # Returns the options of the SmartContract, if deployed via CDP.
    # Returns nil for externally registered contracts.
    # @return [Coinbase::Client::SmartContractOptions, nil] The SmartContract options
    def options
      @model.options
    end

    # Returns whether the SmartContract is an externally registered contract or a CDP managed contract.
    # @return [Boolean] Whether the SmartContract is external
    def external?
      @model.is_external
    end

    # Returns the transaction, if deployed via CDP.
    # @return [Coinbase::Transaction] The SmartContract deployment transaction
    def transaction
      @transaction ||= @model.transaction.nil? ? nil : Coinbase::Transaction.new(@model.transaction)
    end

    # Returns the status of the SmartContract, if deployed via CDP.
    # @return [String] The status
    def status
      transaction&.status
    end

    def update(name: nil, abi: nil)
      req = {}
      req[:contract_name] = name unless name.nil?
      req[:abi] = self.class.normalize_abi(abi).to_json unless abi.nil?

      @model = Coinbase.call_api do
        smart_contracts_api.update_smart_contract(
          network.normalized_id,
          contract_address,
          update_smart_contract_request: req
        )
      end

      self
    end

    # Signs the SmartContract deployment transaction with the given key.
    # This is required before broadcasting the SmartContract.
    # @param key [Eth::Key] The key to sign the SmartContract with
    # @return [SmartContract] The SmartContract object
    # @raise [RuntimeError] If the key is not an Eth::Key
    # @raise [RuntimeError] If the SmartContract is external
    # @raise [Coinbase::AlreadySignedError] If the SmartContract has already been signed
    def sign(key)
      raise ManageExternalContractError, 'sign' if external?
      raise unless key.is_a?(Eth::Key)

      transaction.sign(key)
    end

    # Deploys the signed SmartContract to the blockchain.
    # @return [SmartContract] The SmartContract object
    # @raise [Coinbase::TransactionNotSignedError] If the SmartContract has not been signed
    # @raise [RuntimeError] If the SmartContract is external
    def deploy!
      raise ManageExternalContractError, 'deploy' if external?
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
      raise ManageExternalContractError, 'reload' if external?

      @model = Coinbase.call_api do
        smart_contracts_api.get_smart_contract(wallet_id, deployer_address, id)
      end

      @transaction = Coinbase::Transaction.new(@model.transaction) if @model.transaction

      self
    end

    # Waits until the Smart Contract deployment is signed or failed by polling the server at the given interval.
    # @param interval_seconds [Integer] The interval at which to poll the server, in seconds
    # @param timeout_seconds [Integer] The maximum amount of time to wait for the Smart Contract,
    # deployment to land on-chain, in seconds
    # @return [SmartContract] The completed Smart Contract object
    # @raise [Timeout::Error] if the Contract Invocation takes longer than the given timeout
    def wait!(interval_seconds = 0.2, timeout_seconds = 20)
      raise ManageExternalContractError, 'wait!' if external?

      start_time = Time.now

      loop do
        reload

        return self if transaction.terminal_state?

        if Time.now - start_time > timeout_seconds
          raise Timeout::Error, 'SmartContract deployment timed out. Try waiting again.'
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
        **{
          network: network.id,
          contract_address: contract_address,
          type: type,
          name: name,
          # Fields only present for CDP managed contracts.
          status: status,
          deployer_address: deployer_address,
          options: options.nil? ? nil : Coinbase.pretty_print_object('Options', **options)
        }.compact
      )
    end

    private

    def smart_contracts_api
      @smart_contracts_api ||= Coinbase::Client::SmartContractsApi.new(Coinbase.configuration.api_client)
    end
  end
  # rubocop:enable Metrics/ClassLength
end
