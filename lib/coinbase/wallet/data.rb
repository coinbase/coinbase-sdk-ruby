# frozen_string_literal: true

module Coinbase
  class Wallet
    # The data required to recreate a Wallet.
    class Data
      attr_reader :wallet_id, :seed, :network_id

      # Returns a new Data object.
      # @param wallet_id [String] The ID of the Wallet
      # @param seed [String] The seed of the Wallet
      # @param network_id [String, nil] The network ID of the Wallet (optional)
      def initialize(wallet_id:, seed:, network_id: nil)
        @wallet_id = wallet_id
        @seed = seed
        @network_id = network_id
      end

      # Converts the Data object to a Hash.
      # @return [Hash] The Hash representation of the Data object
      def to_hash
        { wallet_id: wallet_id, seed: seed, network_id: network_id }
      end

      # Creates a Data object from the given Hash.
      # @param data [Hash] The Hash to create the Data object from
      # @return [Data] The new Data object
      def self.from_hash(data)
        Data.new(wallet_id: data['wallet_id'], seed: data['seed'], network_id: data['network_id'])
      end
    end
  end
end
