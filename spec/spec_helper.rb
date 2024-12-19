# frozen_string_literal: true

require 'eth'
require 'simplecov'
require 'pry'
require 'active_support/inflector' # Required for factory_bot
require 'factory_bot'

SimpleCov.start do
  enable_coverage :branch
  primary_coverage :branch
  add_filter '/spec/'
  add_filter '/lib/coinbase/client/'
end

require_relative '../lib/coinbase'
require_relative 'support/shared_examples/address_balances'
require_relative 'support/shared_examples/address_staking'
require_relative 'support/shared_examples/address_transactions'
require_relative 'support/shared_examples/pagination'
require_relative 'support/shared_examples/address_reputation'

# Networks and Asset symbols used in our test factories.
NETWORK_TRAITS = %i[base_mainnet base_sepolia ethereum_holesky ethereum_mainnet].freeze
ASSET_TRAITS = %i[eth usdc weth].freeze
TX_TRAITS = %i[pending signed broadcasted completed failed].freeze
PAYLOAD_SIGNATURE_TRAITS = %i[pending signed failed].freeze

RSpec.configure do |config|
  config.include FactoryBot::Syntax::Methods

  config.before(:suite) do
    FactoryBot.find_definitions
  end
end
