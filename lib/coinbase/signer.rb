# frozen_string_literal: true

require_relative 'client'

module Coinbase
  # A representation of a Signer. Signers are assigned to sign transactions for a Wallet.
  class Signer
    # Returns a new Signer object. Do not use this method directly. Instead, use Signer.default.
    def initialize(model)
      @model = model
    end

    class << self
      # Returns the default Signer for the CDP Project.
      # @return [Coinbase::Signer] the default Signer
      def default
        response = Coinbase.call_api do
          signers_api.list_server_signers
        end

        raise "No Signer's associated with the project" if response.data.empty?

        new(response.data.first)
      end

      def signers_api
        Coinbase::Client::ServerSignersApi.new(Coinbase.configuration.api_client)
      end
    end

    # Returns the Signer ID.
    # @return [String] the Signer ID
    def id
      @model.server_signer_id
    end

    # Returns the IDs of the Wallet's the Signer can sign for.
    # @return [Array<String>] the wallet IDs
    def wallets
      @model.wallets
    end

    # Returns a string representation of the Signer.
    # @return [String] a string representation of the Signer
    def to_s
      "Coinbase::Signer{signer_id: '#{id}', wallets: [#{wallets.join(', ')}]}"
    end

    # Same as to_s.
    # @return [String] a string representation of the Signer
    def inspect
      to_s
    end
  end
end
