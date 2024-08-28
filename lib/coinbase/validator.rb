# frozen_string_literal: true

module Coinbase
  # A representation of a staking validator.
  class Validator
    class << self
      # Returns a list of Validators for the provided network and asset.
      # @param network [Coinbase::Nework, Symbol] The Network or Network ID
      # @param asset_id [Symbol] The asset ID
      # @param status [Symbol] The status of the validator. Defaults to nil.
      # @return [Enumerable<Coinbase::Validator>] The validators
      def list(network, asset_id, status: nil)
        network = Coinbase::Network.from_id(network)

        Coinbase::Pagination.enumerate(lambda { |page|
          list_page(network, asset_id, status, page)
        }) do |validator|
          new(validator)
        end
      end

      # Returns a Validator for the provided network, asset, and validator.
      # @param network [Coinbase::Network, Symbol] The Network or Network ID
      # @param asset_id [Symbol] The asset ID
      # @param validator_id [String] The validator ID
      # @return [Coinbase::Validator] The validator
      def fetch(network, asset_id, validator_id)
        network = Coinbase::Network.from_id(network)

        validator = Coinbase.call_api do
          validators_api.get_validator(
            network.normalized_id,
            asset_id,
            validator_id
          )
        end
        new(validator)
      end

      private

      def list_page(network, asset_id, status, page)
        Coinbase.call_api do
          validators_api.list_validators(
            network.normalized_id,
            asset_id,
            {
              status: status,
              page: page
            }
          )
        end
      end

      def validators_api
        Coinbase::Client::ValidatorsApi.new(Coinbase.configuration.api_client)
      end
    end

    # Returns a new Validator object.
    # @param model [Coinbase::Client::Validator] The underlying Validator object
    def initialize(model)
      @model = model
    end

    # Returns the public identifiable id of the Validator.
    # @return [String] The validator ID
    def validator_id
      @model.validator_id
    end

    # Returns the status of the Validator.
    # @return [Symbol] The status
    def status
      @model.status
    end

    # Returns a string representation of the Validator.
    # @return [String] a string representation of the Validator
    def to_s
      "Coinbase::Validator{id: '#{validator_id}' status: '#{status}'}"
    end

    # Same as to_s.
    # @return [String] a string representation of the Validator
    def inspect
      to_s
    end
  end
end
