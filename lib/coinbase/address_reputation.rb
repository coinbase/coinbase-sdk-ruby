# frozen_string_literal: true

module Coinbase
  # A representation of the reputation of a blockchain address.
  class AddressReputation
    # A metadata object associated with an address reputation.
    Metadata = Struct.new(
      *Client::AddressReputationMetadata.attribute_map.keys.map(&:to_sym),
      keyword_init: true
    ) do
      def to_s
        Coinbase.pretty_print_object(
          self.class,
          **to_h
        )
      end
    end

    class << self
      def fetch(address_id:, network: Coinbase.default_network)
        network = Coinbase::Network.from_id(network)

        model = Coinbase.call_api do
          reputation_api.get_address_reputation(network.normalized_id, address_id)
        end

        new(model)
      end

      private

      def reputation_api
        Coinbase::Client::ReputationApi.new(Coinbase.configuration.api_client)
      end
    end

    def initialize(model)
      unless model.is_a?(Coinbase::Client::AddressReputation)
        raise ArgumentError,
              'must be an AddressReputation client object'
      end

      @model = model
    end

    def score
      @model.score
    end

    def metadata
      @metadata ||= Metadata.new(**@model.metadata)
    end

    def risky?
      score.negative?
    end

    def to_s
      Coinbase.pretty_print_object(
        self.class,
        score: score,
        **metadata.to_h
      )
    end

    def inspect
      to_s
    end
  end
end
