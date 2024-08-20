# frozen_string_literal: true

require_relative 'client/api_error'
require 'json'

module Coinbase
  # A wrapper for API errors to provide more context.
  class APIError < StandardError
    attr_reader :http_code, :api_code, :api_message, :handled

    # Initializes a new APIError object.
    # @param err [Coinbase::Client::APIError] The underlying error object.
    def initialize(err, code: nil, message: nil, unhandled: false)
      @http_code = err.code
      @api_code = code
      @api_message = message
      @handled = code && message && !unhandled

      super(err)
    end

    # Creates a specific APIError based on the API error code.
    # @param err [Coinbase::Client::APIError] The underlying error object.
    # @return [APIError] The specific APIError object.
    def self.from_error(err)
      raise ArgumentError, 'Argument must be a Coinbase::Client::APIError' unless err.is_a? Coinbase::Client::ApiError
      return APIError.new(err) unless err.response_body

      begin
        body = JSON.parse(err.response_body)
      rescue JSON::ParserError
        return APIError.new(err)
      end

      message = body['message']
      code = body['code']

      if ERROR_CODE_TO_ERROR_CLASS.key?(code)
        ERROR_CODE_TO_ERROR_CLASS[code].new(err, code: code, message: message)
      else
        APIError.new(err, code: code, message: message, unhandled: true)
      end
    end

    # Override to_s to display a friendly error message
    def to_s
      # For handled errors, display just the API message as that provides sufficient context.
      return api_message if handled

      # For unhandled errors, display the full error message
      super
    end

    def inspect
      to_s
    end
  end

  # An error raised when an operation is attempted with insufficient funds.
  class NetworkUnsupportedError < StandardError
    def initialize(network_id)
      super("Network #{network_id} is not supported")
    end
  end

  # An error raised when an operation is attempted with insufficient funds.
  class InsufficientFundsError < StandardError
    def initialize(expected, exact, msg = 'Insufficient funds')
      super("#{msg}: have #{exact}, need #{expected}.")
    end
  end

  # An error raised when a resource is already signed.
  class AlreadySignedError < StandardError
    def initialize(msg = 'Resource already signed')
      super(msg)
    end
  end

  # An error raised when a transaction is not signed.
  class TransactionNotSignedError < StandardError
    def initialize(msg = 'Transaction must be signed')
      super(msg)
    end
  end

  # An error raised when an address attempts to sign a transaction without a private key.
  class AddressCannotSignError < StandardError
    def initialize(msg = 'Address cannot sign transaction without private key loaded')
      super(msg)
    end
  end

  class UnimplementedError < APIError; end
  class UnauthorizedError < APIError; end
  class InternalError < APIError; end
  class NotFoundError < APIError; end
  class InvalidWalletIDError < APIError; end
  class InvalidAddressIDError < APIError; end
  class InvalidWalletError < APIError; end
  class InvalidAddressError < APIError; end
  class InvalidAmountError < APIError; end
  class InvalidTransferIDError < APIError; end
  class InvalidPageError < APIError; end
  class InvalidLimitError < APIError; end
  class AlreadyExistsError < APIError; end
  class MalformedRequestError < APIError; end
  class UnsupportedAssetError < APIError; end
  class InvalidAssetIDError < APIError; end
  class InvalidDestinationError < APIError; end
  class InvalidNetworkIDError < APIError; end
  class ResourceExhaustedError < APIError; end
  class FaucetLimitReachedError < APIError; end
  class InvalidSignedPayloadError < APIError; end
  class InvalidTransferStatusError < APIError; end
  class NetworkFeatureUnsupportedError < APIError; end

  ERROR_CODE_TO_ERROR_CLASS = {
    'unimplemented' => UnimplementedError,
    'unauthorized' => UnauthorizedError,
    'internal' => InternalError,
    'not_found' => NotFoundError,
    'invalid_wallet_id' => InvalidWalletIDError,
    'invalid_address_id' => InvalidAddressIDError,
    'invalid_wallet' => InvalidWalletError,
    'invalid_address' => InvalidAddressError,
    'invalid_amount' => InvalidAmountError,
    'invalid_transfer_id' => InvalidTransferIDError,
    'invalid_page_token' => InvalidPageError,
    'invalid_page_limit' => InvalidLimitError,
    'already_exists' => AlreadyExistsError,
    'malformed_request' => MalformedRequestError,
    'unsupported_asset' => UnsupportedAssetError,
    'invalid_asset_id' => InvalidAssetIDError,
    'invalid_destination' => InvalidDestinationError,
    'invalid_network_id' => InvalidNetworkIDError,
    'resource_exhausted' => ResourceExhaustedError,
    'faucet_limit_reached' => FaucetLimitReachedError,
    'invalid_signed_payload' => InvalidSignedPayloadError,
    'invalid_transfer_status' => InvalidTransferStatusError,
    'network_feature_unsupported' => NetworkFeatureUnsupportedError
  }.freeze
end
