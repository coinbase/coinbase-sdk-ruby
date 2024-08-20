# frozen_string_literal: true

require 'faraday'
require 'securerandom'

module Coinbase
  # A middleware that injects correlation data into the request headers.
  class Correlation < Faraday::Middleware
    # Initializes the Correlation middleware.
    # @param app [Faraday::Connection] The Faraday connection
    def initialize(app)
      super(app)
      @app = app
    end

    # Processes the request by adding the Correlation Data to the request headers.
    # @param env [Faraday::Env] The Faraday request environment
    def call(env)
      env.request_headers['Correlation-Context'] = correlation_data
      @app.call(env)
    end

    def correlation_data
      @correlation_data ||= {
        sdk_version: Coinbase::VERSION,
        sdk_language: 'ruby'
      }.map { |key, val| "#{key}=#{CGI.escape(val)}" }.join(',')
    end
  end
end
