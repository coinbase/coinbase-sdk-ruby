# frozen_string_literal: true

require 'eth'

module Coinbase
  # A representation of an onchain Sponsored Send.
  # Sponsored Sends should be constructed via higher level abstractions like Transfer.
  class SponsoredSend
    # A representation of a Transaction status.
    module Status
      # The SponsoredSend is awaiting being signed.
      PENDING = 'pending'

      # The Sponsored Send has been signed, but has not been submitted to be
      # built into a transaction yet.
      SIGNED = 'signed'

      # The Sponsored Send has been submitted to be built into a transaction,
      # that the sponsor will sign and submit to the network.
      # At this point, transaction hashes may not yet be assigned.
      SUBMITTED = 'submitted'

      # The Sponsored Send's corresponding transaction is complete and has
      # confirmed on the Network.
      COMPLETE = 'complete'

      # The Sponsored Send has failed for some reason.
      FAILED = 'failed'

      # The states that are considered terminal on-chain.
      TERMINAL_STATES = [COMPLETE, FAILED].freeze
    end

    # Returns a new SponsoredSend object. Do not use this method directly.
    # @param model [Coinbase::Client::SponsoredSend] The underlying SponsoredSend object
    def initialize(model)
      raise unless model.is_a?(Coinbase::Client::SponsoredSend)

      @model = model
    end

    # Returns the Keccak256 hash of the typed data. This payload must be signed
    # by the sender to be used as an approval in the EIP-3009 transaction.
    # @return [String] The Keccak256 hash of the typed data
    def typed_data_hash
      @model.typed_data_hash
    end

    # Returns the signature of the typed data.
    def signature
      @signature ||= @model.signature
    end

    # Signs the Transaction with the provided key and returns the hex signing payload.
    # @return [String] The hex-encoded signed payload
    def sign(key)
      raise unless key.is_a?(Eth::Key)
      raise Coinbase::AlreadySignedError if signed?

      @signature = Eth::Util.prefix_hex(key.sign(Eth::Util.hex_to_bin(typed_data_hash)))
    end

    # Returns whether the Transaction has been signed.
    # @return [Boolean] Whether the Transaction has been signed
    def signed?
      !signature.nil?
    end

    # Returns the status of the Transaction.
    # @return [Symbol] The status
    def status
      @model.status
    end

    # Returns whether the Sponsored Send is in a terminal state.
    # @return [Boolean] Whether the Transaction is in a terminal state
    def terminal_state?
      Status::TERMINAL_STATES.include?(status)
    end

    # Returns the Transaction Hash of the Transaction.
    # @return [String] The Transaction Hash
    def transaction_hash
      @model.transaction_hash
    end

    # Returns the link to the transaction on the blockchain explorer.
    # @return [String] The link to the transaction on the blockchain explorer
    def transaction_link
      @model.transaction_link
    end

    # Returns a String representation of the SponsoredSend.
    # @return [String] a String representation of the SponsoredSend
    def to_s
      Coinbase.pretty_print_object(
        self.class,
        status: status,
        transaction_hash: transaction_hash,
        transaction_link: transaction_link
      )
    end

    # Same as to_s.
    # @return [String] a String representation of the SponsoredSend
    def inspect
      to_s
    end
  end
end
