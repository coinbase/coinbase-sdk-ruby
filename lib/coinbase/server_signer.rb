# frozen_string_literal: true

require_relative 'client'

module Coinbase
  # A representation of a Server-Signer. Server-Signers are assigned to sign transactions for a Wallet.
  class ServerSigner
    # A representation of ServerSigner status in a Wallet.
    module Status
      # The Wallet is awaiting seed creation by the ServerSigner. At this point,
      # the Wallet cannot create addresses or sign transactions.
      PENDING = 'pending_seed_creation'

      # The Wallet has an associated seed created by the ServerSigner. It is ready
      # to create addresses and sign transactions.
      ACTIVE = 'active_seed'
    end

    class << self
      # Returns the default ServerSigner for the CDP Project.
      # @return [Coinbase::ServerSigner] the default Server-Signer
      def default
        response = Coinbase.call_api do
          server_signers_api.list_server_signers
        end

        raise 'No Server-Signer is associated with the project' if response.data.empty?

        new(response.data.first)
      end

      private

      def server_signers_api
        Coinbase::Client::ServerSignersApi.new(Coinbase.configuration.api_client)
      end
    end

    # Returns a new Server-Signer object. Do not use this method directly. Instead, use ServerSigner.default.
    def initialize(model)
      @model = model
    end

    # Returns the Server-Signer ID.
    # @return [String] the Server-Signer ID
    def id
      @model.server_signer_id
    end

    # Returns the IDs of the Wallet's the Server-Signer can sign for.
    # @return [Array<String>] the wallet IDs
    def wallets
      @model.wallets
    end

    # Returns a string representation of the Server-Signer.
    # @return [String] a string representation of the Server-Signer
    def to_s
      "Coinbase::ServerSigner{server_signer_id: '#{id}', wallets: [#{wallets.join(', ')}]}"
    end

    # Same as to_s.
    # @return [String] a string representation of the Server-Signer
    def inspect
      to_s
    end
  end
end
