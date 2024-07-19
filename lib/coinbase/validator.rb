# frozen_string_literal: true

module Coinbase
  # A representation of a staking validator.
  class Validator
    # Returns a new Validator object.
    # @param model [Coinbase::Client::Validator] The underlying Validator object
    def initialize(model)
      @model = model
    end

    # Returns a list of Validators for the provided network and asset.
    # @param network_id [Symbol] The network ID
    # @param asset_id [Symbol] The asset ID
    # @param status [Symbol] The status of the validator. Defaults to nil.
    # @return [Enumerable<Coinbase::Validator>] The validators
    def self.list(network_id, asset_id, status: nil)
      Coinbase::Pagination.enumerate(
        ->(page) { list_page(network_id, asset_id, status, page) }
      ) do |validator|
        new(validator)
      end
    end

    # Returns a Validator for the provided network, asset, and validator.
    # @param network_id [Symbol] The network ID
    # @param asset_id [Symbol] The asset ID
    # @param validator_id [String] The validator ID
    # @return [Coinbase::Validator] The validator
    def self.fetch(network_id, asset_id, validator_id)
      validator = Coinbase.call_api do
        validators_api.get_validator(
          network_id,
          asset_id,
          validator_id
        )
      end
      new(validator)
    end

    # Returns the public identifiable id of the Validator.
    # @return [String] The validator id
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

    def self.list_page(network_id, asset_id, status, page)
      Coinbase.call_api do
        validators_api.list_validators(
          network_id,
          asset_id,
          {
            status: status,
            page: page
          }
        )
      end
    end

    def self.validators_api
      Coinbase::Client::ValidatorsApi.new(Coinbase.configuration.api_client)
    end
  end
end
