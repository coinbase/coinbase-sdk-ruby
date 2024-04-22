# frozen_string_literal: true

require 'jwt'
require 'openssl'
require 'securerandom'

module Coinbase
  # A class that builds JWTs for authenticating with the Coinbase Platform APIs.
  class Authenticator < Faraday::Middleware

    # Initializes the Authenticator.
    # @param app [Faraday::Connection] The Faraday connection
    def initialize(app)
      super(app)
      @app = app
    end

    # Processes the request by adding the JWT to the Authorization header.
    # @param env [Faraday::Env] The Faraday request environment
    def call(env)
      method = env.method.downcase.to_sym
      uri = env.url.to_s
      uri_without_protocol = URI(uri).host
      build_jwt("#{method.upcase} #{uri_without_protocol}#{env.url.path}")
      env.request_headers['Authorization'] = "Bearer #{token}"
      @app.call(env)
    end

    # Builds the JWT for the given API endpoint URI. The JWT is signed with the API key's private key.
    # @param uri [String] The API endpoint URI
    # @return [String] The JWT
    def self.build_jwt(uri)
      header = {
        typ: 'JWT',
        kid: Coinbase.api_key_name,
        nonce: SecureRandom.hex(16)
      }

      claims = {
        sub: Coinbase.api_key_name,
        iss: 'coinbase-cloud',
        aud: ['cdp_service'],
        nbf: Time.now.to_i,
        exp: Time.now.to_i + 60, # Expiration time: 1 minute from now.
        uris: [uri]
      }

      private_key = OpenSSL::PKey.read(Coinbase.api_key_private_key)
      JWT.encode(claims, private_key, 'ES256', header)
    end
  end
end
