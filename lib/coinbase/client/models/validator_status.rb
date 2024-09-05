=begin
#Coinbase Platform API

#This is the OpenAPI 3.0 specification for the Coinbase Platform APIs, used in conjunction with the Coinbase Platform SDKs.

The version of the OpenAPI document: 0.0.1-alpha

Generated by: https://openapi-generator.tech
Generator version: 7.7.0

=end

require 'date'
require 'time'

module Coinbase::Client
  class ValidatorStatus
    UNKNOWN = "unknown".freeze
    PROVISIONING = "provisioning".freeze
    PROVISIONED = "provisioned".freeze
    DEPOSITED = "deposited".freeze
    PENDING_ACTIVATION = "pending_activation".freeze
    ACTIVE = "active".freeze
    EXITING = "exiting".freeze
    EXITED = "exited".freeze
    WITHDRAWAL_AVAILABLE = "withdrawal_available".freeze
    WITHDRAWAL_COMPLETE = "withdrawal_complete".freeze
    ACTIVE_SLASHED = "active_slashed".freeze
    EXITED_SLASHED = "exited_slashed".freeze
    REAPED = "reaped".freeze
    UNKNOWN_DEFAULT_OPEN_API = "unknown_default_open_api".freeze

    def self.all_vars
      @all_vars ||= [UNKNOWN, PROVISIONING, PROVISIONED, DEPOSITED, PENDING_ACTIVATION, ACTIVE, EXITING, EXITED, WITHDRAWAL_AVAILABLE, WITHDRAWAL_COMPLETE, ACTIVE_SLASHED, EXITED_SLASHED, REAPED, UNKNOWN_DEFAULT_OPEN_API].freeze
    end

    # Builds the enum from string
    # @param [String] The enum value in the form of the string
    # @return [String] The enum value
    def self.build_from_hash(value)
      new.build_from_hash(value)
    end

    # Builds the enum from string
    # @param [String] The enum value in the form of the string
    # @return [String] The enum value
    def build_from_hash(value)
      return value if ValidatorStatus.all_vars.include?(value)
      raise "Invalid ENUM value #{value} for class #ValidatorStatus"
    end
  end
end
