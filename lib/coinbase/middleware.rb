# frozen_string_literal: true

require_relative 'authenticator'
require_relative 'client/configuration'
require 'faraday'
require 'faraday/retry'

module Coinbase
  # A module for middleware that can be used with Faraday.
  module Middleware
    Faraday::Request.register_middleware authenticator: -> { Coinbase::Authenticator }
    Faraday::Request.register_middleware correlation: -> { Coinbase::Correlation }

    class << self
      # Returns the default middleware configuration for the Coinbase SDK.
      def config
        Coinbase::Client::Configuration.default.tap do |config|
          uri = URI(Coinbase.configuration.api_url)

          config.debugging = Coinbase.configuration.debug_api
          config.host = uri.host + (uri.port ? ":#{uri.port}" : '')
          config.scheme = uri.scheme if uri.scheme
          config.request(:authenticator)
          config.request(:correlation)
          retry_options = {
            max: Coinbase.configuration.max_network_tries,
            interval: 0.05,
            interval_randomness: 0.5,
            backoff_factor: 2,
            methods: %i[get],
            retry_statuses: [500, 502, 503, 504]
          }
          config.configure_faraday_connection do |conn|
            conn.request :retry, retry_options
          end
        end
      end
    end
  end
end
