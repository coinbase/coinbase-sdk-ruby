# frozen_string_literal: true

require_relative 'coinbase/address'
require_relative 'coinbase/balance_map'
require_relative 'coinbase/constants'
require_relative 'coinbase/network'
require_relative 'coinbase/transfer'
require_relative 'coinbase/wallet'
require 'dotenv'

# The Coinbase SDK.
module Coinbase
  # Initializes the Coinbase SDK.
  def self.init
    Dotenv.load
  end

  def self.api_key_name
    @api_key_name
  end

  def self.api_key_name=(api_key_name)
    @api_key_name = api_key_name
  end

  def self.api_key_secret
    @api_key_secret
  end

  def self.api_key_secret=(api_key_secret)
    @api_key_secret = api_key_secret
  end
end
