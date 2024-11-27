=begin
#Coinbase Platform API

#This is the OpenAPI 3.0 specification for the Coinbase Platform APIs, used in conjunction with the Coinbase Platform SDKs.

The version of the OpenAPI document: 0.0.1-alpha

Generated by: https://openapi-generator.tech
Generator version: 7.9.0

=end

require 'date'
require 'time'

module Coinbase::Client
  class SmartContractType
    ERC20 = "erc20".freeze
    ERC721 = "erc721".freeze
    ERC1155 = "erc1155".freeze
    UNKNOWN_DEFAULT_OPEN_API = "unknown_default_open_api".freeze

    def self.all_vars
      @all_vars ||= [ERC20, ERC721, ERC1155, UNKNOWN_DEFAULT_OPEN_API].freeze
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
      return value if SmartContractType.all_vars.include?(value)
      raise "Invalid ENUM value #{value} for class #SmartContractType"
    end
  end
end
