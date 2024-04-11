# frozen_string_literal: true

require_relative 'coinbase/address'
require_relative 'coinbase/network'
require_relative 'coinbase/wallet'
require 'dotenv'
require 'json'

# The Coinbase SDK.
module Coinbase
  # Initializes the Coinbase SDK using the passed API key JSON file.
  # @param api_key_file [String] The path to the API key JSON file
  def self.init_json(api_key_file)
    Dotenv.load
    file = File.read(api_key_file)
    data = JSON.parse(file)
    @api_key_name = data['name']
    @api_key_secret = data['privateKey']
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
