# frozen_string_literal: true

require 'eth'
require 'json'

module Coinbase
  # A representation of an onchain Transaction.
  # Transactions should be constructed via higher level abstractions like Trade or Transfer.
  class Transaction
    # A representation of a Transaction status.
    module Status
      # The Transaction is awaiting being broadcast to the Network.
      # At this point, transaction hashes may not yet be assigned.
      PENDING = 'pending'

      # The Transaction has been signed, but has not been successfully broadcast yet.
      SIGNED = 'signed'

      # The Transaction has been broadcast to the Network.
      # At this point, at least the transaction hash should be assigned.
      BROADCAST = 'broadcast'

      # The Transaction is complete and has confirmed on the Network.
      COMPLETE = 'complete'

      # The Transaction has failed for some reason.
      FAILED = 'failed'

      # The Transaction isn't specified it's status in Receipt.
      UNSPECIFIED = 'unspecified'

      # The states that are considered terminal on-chain.
      TERMINAL_STATES = [COMPLETE, FAILED].freeze
    end

    # Returns a new Transaction object. Do not use this method directly.
    # @param model [Coinbase::Client::Transaction] The underlying Transaction object
    def initialize(model)
      raise unless model.is_a?(Coinbase::Client::Transaction)

      @model = model
    end

    # Returns the Unsigned Payload of the Transaction.
    # @return [String] The Unsigned Payload
    def unsigned_payload
      @model.unsigned_payload
    end

    # Returns the Signed Payload of the Transaction.
    # @return [String] The Signed Payload
    def signed_payload
      @model.signed_payload
    end

    # Returns the Transaction Hash of the Transaction.
    # @return [String] The Transaction Hash
    def transaction_hash
      @model.transaction_hash
    end

    # Returns the status of the Transaction.
    # @return [Symbol] The status
    def status
      @model.status
    end

    # Returns the from address for the Transaction.
    # @return [String] The from address
    def from_address_id
      @model.from_address_id
    end

    # Returns the to address for the Transaction.
    # @return [String] The to address
    def to_address_id
      @model.to_address_id
    end

    # Returns whether the Transaction is in a terminal state.
    # @return [Boolean] Whether the Transaction is in a terminal state
    def terminal_state?
      Status::TERMINAL_STATES.include?(status)
    end

    # Returns the block hash of which the Transaction is recorded.
    # @return [String] The to block_hash
    def block_hash
      @model.block_hash
    end

    # Returns the block height of which the Transaction is recorded.
    # @return [String] The to block_height
    def block_height
      @model.block_height
    end

    # Returns the link to the transaction on the blockchain explorer.
    # @return [String] The link to the transaction on the blockchain explorer
    def transaction_link
      @model.transaction_link
    end

    # Returns the block height of which the Transaction is recorded.
    # @return [String] The to block_height
    def content
      @model.content
    end

    # Returns the underlying raw transaction.
    # @return [Eth::Tx::Eip1559] The raw transaction
    def raw
      return @raw unless @raw.nil?

      # If the transaction is signed, decode the signed payload.
      unless signed_payload.nil?
        @raw = Eth::Tx::Eip1559.decode(signed_payload)

        return @raw
      end

      # If the transaction is unsigned, parse the unsigned payload into an EIP-1559 transaction.
      raw_payload = [unsigned_payload].pack('H*')
      parsed_payload = JSON.parse(raw_payload)

      params = {
        chain_id: parsed_payload['chainId'].to_i(16),
        nonce: parsed_payload['nonce'].to_i(16),
        priority_fee: parsed_payload['maxPriorityFeePerGas'].to_i(16),
        max_gas_fee: parsed_payload['maxFeePerGas'].to_i(16),
        gas_limit: parsed_payload['gas'].to_i(16), # TODO: Handle multiple currencies.
        from: from_address_id,
        to: parsed_payload['to'],
        value: parsed_payload['value'].to_i(16),
        data: parsed_payload['input'] || ''
      }

      @raw = Eth::Tx::Eip1559.new(Eth::Tx.validate_eip1559_params(params))
    end

    # Returns the signature of the Transaction.
    # @return [String] The hex-encode signature
    def signature
      raw.hex
    end

    # Signs the Transaction with the provided key and returns the hex signing payload.
    # @return [String] The hex-encoded signed payload
    def sign(key)
      raise 'Invalid key type' unless key.is_a?(Eth::Key)
      raise Coinbase::AlreadySignedError if signed?

      raw.sign(key)

      signature
    end

    # Returns whether the Transaction has been signed.
    # @return [Boolean] Whether the Transaction has been signed
    def signed?
      Eth::Tx.signed?(raw)
    end

    # Returns a String representation of the Transaction.
    # @return [String] a String representation of the Transaction
    def to_s
      "Coinbase::Transaction{transaction_hash: '#{transaction_hash}', status: '#{status}'}"
    end

    # Same as to_s.
    # @return [String] a String representation of the Transaction
    def inspect
      to_s
    end
  end
end
