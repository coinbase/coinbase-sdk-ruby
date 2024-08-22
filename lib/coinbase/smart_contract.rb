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
          list_events_page(network_id, protocol_name, contract_address, contract_name, event_name, from_block_height,
                           to_block_height, page)
        }
      ) do |contract_event|
        Coinbase::ContractEvent.new(contract_event)
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
end
