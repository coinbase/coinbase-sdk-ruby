# frozen_string_literal: true

require 'date'

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
      network_id,
      protocol_name,
      contract_address,
      contract_name,
      event_name,
      from_block_height,
      to_block_height
    )
      Coinbase::Pagination.enumerate(
        lambda { |page|
          list_events_page(network_id, protocol_name, contract_address, contract_name, event_name, from_block_height,
                           to_block_height, page)
        }
      ) do |contract_event|
        ContractEvent.new(contract_event)
      end
    end

    # Returns a new SmartContract object.
    # @param model [Coinbase::Client::SmartContract] The underlying SmartContract object
    def initialize(model)
      @model = model
    end

    # Returns the network ID of the SmartContract.
    # @return [String] The network ID
    def network_id
      Coinbase.to_sym(@model.network_id)
    end

    # Returns the protocol name of the SmartContract.
    # @return [String] The protocol name
    def protocol_name
      @model.protocol_name
    end

    # Returns the contract name of the SmartContract.
    # @return [String] The contract name
    def contract_name
      @model.contract_name
    end

    # Returns the address of the SmartContract.
    # @return [String] The contract address
    def address
      @model.address
    end

    # Returns a string representation of the SmartContract.
    # @return [String] a string representation of the SmartContract
    def to_s
      "Coinbase::SmartContract{
        network_id: '#{network_id}',
        protocol_name: '#{protocol_name}',
        contract_name: '#{contract_name}',
        address: '#{address}'}"
    end

    # Same as to_s.
    # @return [String] a string representation of the SmartContract
    def inspect
      to_s
    end

    def self.contract_events_api
      Coinbase::Client::ContractEventsApi.new(Coinbase.configuration.api_client)
    end

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
        contract_address,
        protocol_name,
        contract_name,
        event_name,
        from_block_height,
        to_block_height,
        page
      )
    end
  end

  # Represents a single contract event
  class ContractEvent
    # Returns a new ContractEvent object.
    # @param model [Coinbase::Client::ContractEvent] The underlying ContractEvent object
    def initialize(model)
      @model = model
    end

    # Returns the network ID of the ContractEvent.
    # @return [String] The network ID
    def network_id
      @model.network_id
    end

    # Returns the protocol name of the ContractEvent.
    # @return [String] The protocol name
    def protocol_name
      @model.protocol_name
    end

    # Returns the contract name of the ContractEvent.
    # @return [String] The contract name
    def contract_name
      @model.contract_name
    end

    # Returns the event name of the ContractEvent.
    # @return [String] The event name
    def event_name
      @model.event_name
    end

    # Returns the signature of the ContractEvent.
    # @return [String] The event signature
    def sig
      @model.sig
    end

    # Returns the four bytes of the Keccak hash of the event signature.
    # @return [String] The four bytes of the event signature hash
    def four_bytes
      @model.four_bytes
    end

    # Returns the contract address of the ContractEvent.
    # @return [String] The contract address
    def contract_address
      @model.contract_address
    end

    # Returns the block time of the ContractEvent.
    # @return [Time] The block time
    def block_time
      Time.parse(@model.block_time)
    end

    # Returns the block height of the ContractEvent.
    # @return [Integer] The block height
    def block_height
      @model.block_height
    end

    # Returns the transaction hash of the ContractEvent.
    # @return [String] The transaction hash
    def tx_hash
      @model.tx_hash
    end

    # Returns the transaction index of the ContractEvent.
    # @return [Integer] The transaction index
    def tx_index
      @model.tx_index
    end

    # Returns the event index of the ContractEvent.
    # @return [Integer] The event index
    def event_index
      @model.event_index
    end

    # Returns the event data of the ContractEvent.
    # @return [String] The event data
    def data
      @model.data
    end

    # Returns a string representation of the ContractEvent.
    # @return [String] a string representation of the ContractEvent
    def to_s
      "Coinbase::ContractEvent{network_id: '#{network_id}', protocol_name: '#{protocol_name}', " \
        "contract_name: '#{contract_name}', event_name: '#{event_name}', contract_address: '#{contract_address}', " \
        "block_height: #{block_height}, tx_hash: '#{tx_hash}'}"
    end

    # Same as to_s.
    # @return [String] a string representation of the ContractEvent
    def inspect
      to_s
    end
  end
end
