# frozen_string_literal: true

module Coinbase
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
        "block_height: #{block_height}, tx_hash: '#{tx_hash}', data: '#{data}'}"
    end

    # Same as to_s.
    # @return [String] a string representation of the ContractEvent
    def inspect
      to_s
    end
  end
end
