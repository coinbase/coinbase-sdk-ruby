# frozen_string_literal: true

require_relative 'client/api_error'
require 'json'

module Coinbase
  # A wrapper for API errors to provide more context.
  class APIError < StandardError
    attr_reader :api_code, :api_message

    # Initializes a new APIError object.
    # @param err [Coinbase::Client::APIError] The underlying error object.
    def initialize(err)
      super
      @e = err

      return unless @e.response_body

      body = JSON.parse(@e.response_body)
      @api_code = body['code']
      @api_message = body['message']
    end

    # Creates a specific APIError based on the API error code.
    # @param err [Coinbase::Client::APIError] The underlying error object.
    # @return [APIError] The specific APIError object.
    def self.from_error(err)
      raise ArgumentError, 'Argument must be a Coinbase::Client::APIError' unless err.is_a? Coinbase::Client::ApiError
      return APIError.new(err) unless err.response_body

      body = JSON.parse(err.response_body)
      api_code = body['code']

      case api_code
      when 'unimplemented'
        UnimplementedError.new(err)
      when 'unauthorized'
        UnauthorizedError.new(err)
      when 'internal'
        InternalError.new(err)
      when 'not_found'
        NotFoundError.new(err)
      when 'invalid_wallet_id'
        InvalidWalletIDError.new(err)
      when 'invalid_address_id'
        InvalidAddressIDError.new(err)
      when 'invalid_wallet'
        InvalidWalletError.new(err)
      when 'invalid_address'
        InvalidAddressError.new(err)
      when 'invalid_amount'
        InvalidAmountError.new(err)
      when 'invalid_transfer_id'
        InvalidTransferIDError.new(err)
      when 'invalid_page_token'
        InvalidPageError.new(err)
      when 'invalid_page_limit'
        InvalidLimitError.new(err)
      when 'already_exists'
        AlreadyExistsError.new(err)
      when 'malformed_request'
        MalformedRequestError.new(err)
      when 'unsupported_asset'
        UnsupportedAssetError.new(err)
      when 'invalid_asset_id'
        InvalidAssetIDError.new(err)
      when 'invalid_destination'
        InvalidDestinationError.new(err)
      when 'invalid_network_id'
        InvalidNetworkIDError.new(err)
      when 'resource_exhausted'
        ResourceExhaustedError.new(err)
      when 'faucet_limit_reached'
        FaucetLimitReachedError.new(err)
      else
        APIError.new(err)
      end
    end

    # Returns the HTTP status code of the error.
    # @return [Integer] The HTTP status code.
    def http_code
      @e.code
    end

    # The string representation of the error.
    def to_s
      message = "API Error \n"
      message += "HTTP status code: #{http_code}\n" if http_code
      message += "API error code: #{api_code}\n" if api_code
      message += "API error message: #{api_message}\n" if api_message
      message
    end
  end

  class UnimplementedError < APIError
  end

  class UnauthorizedError < APIError
  end

  class InternalError < APIError
  end

  class NotFoundError < APIError
  end

  class InvalidWalletIDError < APIError
  end

  class InvalidAddressIDError < APIError
  end

  class InvalidWalletError < APIError
  end

  class InvalidAddressError < APIError
  end

  class InvalidAmountError < APIError
  end

  class InvalidTransferIDError < APIError
  end

  class InvalidPageError < APIError
  end

  class InvalidLimitError < APIError
  end

  class AlreadyExistsError < APIError
  end

  class MalformedRequestError < APIError
  end

  class UnsupportedAssetError < APIError
  end

  class InvalidAssetIDError < APIError
  end

  class InvalidDestinationError < APIError
  end

  class InvalidNetworkIDError < APIError
  end

  class ResourceExhaustedError < APIError
  end

  class FaucetLimitReachedError < APIError
  end
end
