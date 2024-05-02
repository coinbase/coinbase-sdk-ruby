# frozen_string_literal: true

require_relative 'client/api_error'
require 'json'

module Coinbase
  # A wrapper for API errors to provide more context.
  class APIError
    attr_reader :api_code, :api_message

    # Initializes a new APIError object.
    #
    # @param err [Coinbase::Client::APIError] The underlying error object.
    def initialize(err)
      @e = err

      return unless e.response_body

      body = JSON.parse(e.response_body)
      @api_code = body['code']
      @api_message = body['message']
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
end
