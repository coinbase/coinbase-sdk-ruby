=begin
#Coinbase Platform API

#This is the OpenAPI 3.0 specification for the Coinbase Platform APIs, used in conjunction with the Coinbase Platform SDKs.

The version of the OpenAPI document: 0.0.1-alpha
Contact: yuga.cohler@coinbase.com
Generated by: https://openapi-generator.tech
Generator version: 7.6.0

=end

require 'date'
require 'time'

module Coinbase::Client
  class WebhookEventType
    UNSPECIFIED = "unspecified".freeze
    ERC20_TRANSFER = "erc20_transfer".freeze
    ERC721_TRANSFER = "erc721_transfer".freeze
    UNKNOWN_DEFAULT_OPEN_API = "unknown_default_open_api".freeze

    def self.all_vars
      @all_vars ||= [UNSPECIFIED, ERC20_TRANSFER, ERC721_TRANSFER, UNKNOWN_DEFAULT_OPEN_API].freeze
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
      return value if WebhookEventType.all_vars.include?(value)
      raise "Invalid ENUM value #{value} for class #WebhookEventType"
    end
  end
end
