require_relative 'client/api_error'
require 'json'

module Coinbase
  # A wrapper for API errors to provide more context.
  class APIError

    # Initializes a new APIError object.
    #
    # @param e [Coinbase::Client::APIError] The underlying error object.
    def initialize(e)
      @e = e

      if e.response_body
        body = JSON.parse(e.response_body)
        @api_code = body['code']
        @api_message = body['message']
      end
    end

    # Returns the HTTP status code of the error.
    # @return [Integer] The HTTP status code.
    def http_code
      @e.code
    end

    # Returns the API error code of the error.
    # @return [String] The API error code.
    def api_code
      @api_code
    end

    # Returns the API error message of the error.
    # @return [String] The API error message.
    def api_message
      @api_message
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
