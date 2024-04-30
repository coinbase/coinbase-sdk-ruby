# frozen_string_literal: true

require_relative 'authenticator'
require_relative 'client/configuration'
require 'faraday'

module Coinbase
  # A module for middleware that can be used with Faraday.
  module Middleware
    Faraday::Request.register_middleware authenticator: -> { Coinbase::Authenticator }

    # Returns the default middleware configuration for the Coinbase SDK.
    def self.config
      Coinbase::Client::Configuration.default.tap do |config|
        config.debugging = true
        config.host = Coinbase.configuration.api_url
        config.request(:authenticator)
      end
    end
  end
end
