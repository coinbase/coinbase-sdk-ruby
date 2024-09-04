# frozen_string_literal: true

require_relative 'constants'

module Coinbase
  # A representation of a Payload Signature.
  class PayloadSignature
    # A representation of a Payload Signature status.
    module Status
      # The Payload Signature is pending signing.
      # At this point, the Signature is not available yet.
      PENDING = 'pending'

      # The Payload Signature has been signed.
      SIGNED = 'signed'

      # The Payload Signature has failed.
      FAILED = 'failed'

      # The states that are considered terminal.
      TERMINAL_STATES = [SIGNED, FAILED].freeze
    end

    class << self
      # Creates a new PayloadSignature object.
      # @param wallet_id [String] The Wallet ID associated with the signing Address
      # @param address_id [String] The Address ID of the signing Address
      # @param unsigned_payload [String] The hex-encoded Unsigned Payload
      # @param signature [String] (Optional) The Signature if the Wallet is not using an MPC Server-Signer
      # @return [PayloadSignature] The new Payload Signature object
      # @raise [Coinbase::ApiError] If the request to create the Payload Signature fails
      def create(wallet_id:, address_id:, unsigned_payload:, signature: nil)
        create_payload_signature_request = {
          unsigned_payload: unsigned_payload,
          signature: signature
        }.compact

        model = Coinbase.call_api do
          addresses_api.create_payload_signature(
            wallet_id,
            address_id,
            create_payload_signature_request: create_payload_signature_request
          )
        end

        new(model)
      end

      # Enumerates the payload signatures for a given address belonging to a wallet.
      # The result is an enumerator that lazily fetches from the server, and can be iterated over,
      # converted an array, etc...
      # @return [Enumerable<Coinbase::PayloadSignature>] Enumerator that returns payload signatures
      def list(wallet_id:, address_id:)
        Coinbase::Pagination.enumerate(
          ->(page) { fetch_page(wallet_id, address_id, page) }
        ) do |payload_signature|
          new(payload_signature)
        end
      end

      private

      def addresses_api
        Coinbase::Client::AddressesApi.new(Coinbase.configuration.api_client)
      end

      def fetch_page(wallet_id, address_id, page)
        addresses_api.list_payload_signatures(wallet_id, address_id, { limit: DEFAULT_PAGE_LIMIT, page: page })
      end
    end

    # Returns a new PayloadSignature object. Do not use this method directly.
    # Instead use Coinbase::PayloadSignature.create.
    # @param model [Coinbase::Client::PayloadSignature] The underlying Payload Signature obejct
    def initialize(model)
      raise unless model.is_a?(Coinbase::Client::PayloadSignature)

      @model = model
    end

    # Returns the Payload Signature ID.
    # @return [String] The Payload Signature ID
    def id
      @model.payload_signature_id
    end

    # Returns the Wallet ID of the Payload Signature.
    # @return [String] The Wallet ID
    def wallet_id
      @model.wallet_id
    end

    # Returns the Address ID of the Payload Signature.
    # @return [String] The Address ID
    def address_id
      @model.address_id
    end

    # Returns the Unsigned Payload of the Payload Signature.
    # @return [String] The Unsigned Payload
    def unsigned_payload
      @model.unsigned_payload
    end

    # Returns the Signature of the Payload Signature.
    # @return [String] The Signature
    def signature
      @signature ||= @model.signature
    end

    # Returns the status of the Payload Signature.
    # @return [Symbol] The status
    def status
      @model.status
    end

    # Returns whether the Payload Signature is in a terminal state.
    # @return [Boolean] Whether the Payload Signature is in a terminal state
    def terminal_state?
      Status::TERMINAL_STATES.include?(status)
    end

    # # Reload reloads the Payload Signature model with the latest version from the server side.
    # @return [PayloadSignature] The most recent version of Payload Signature from the server
    def reload
      @model = Coinbase.call_api do
        addresses_api.get_payload_signature(wallet_id, address_id, id)
      end

      self
    end

    # Waits until the Payload Signature is signed or failed by polling the server at the given interval. Raises a
    # Timeout::Error if the Payload Signature takes longer than the given timeout.
    # @param interval_seconds [Integer] The interval at which to poll the server, in seconds
    # @param timeout_seconds [Integer] The maximum amount of time to wait for the Payload Signature to be signed,
    # in seconds.
    # @return [PayloadSignature] The completed Payload Signature object
    def wait!(interval_seconds = 0.2, timeout_seconds = 20)
      start_time = Time.now

      loop do
        reload

        return self if terminal_state?

        raise Timeout::Error, 'Payload Signature timed out' if Time.now - start_time > timeout_seconds

        self.sleep interval_seconds
      end

      self
    end

    # Returns a String representation of the Payload Signature.
    # @return [String] a String representation of the Payload Signature
    def to_s
      Coinbase.pretty_print_object(
        self.class,
        id: id,
        wallet_id: wallet_id,
        address_id: address_id,
        status: status,
        unsigned_payload: unsigned_payload,
        signature: signature
      )
    end

    # Same as to_s.
    # @return [String] a String representation of the PayloadSignature
    def inspect
      to_s
    end

    def addresses_api
      Coinbase::Client::AddressesApi.new(Coinbase.configuration.api_client)
    end
  end
end
