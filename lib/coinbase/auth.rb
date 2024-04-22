# frozen_string_literal: true

require 'jwt'
require 'openssl'
require 'securerandom'

module Coinbase
  # Methods for authenticating with the Coinbase Platform APIs.
  module Auth
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
