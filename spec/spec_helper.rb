# frozen_string_literal: true

require 'simplecov'
require 'pry'
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
require_relative 'support/shared_examples/pagination'

RSpec.configure do |config|
  TEST_ASSET_SYMBOLS = %i[eth usdc weth]
  TEST_NETWORKS = %i[base_mainnet base_sepolia ethereum_holesky ethereum_mainnet]

  config.include FactoryBot::Syntax::Methods

  config.before(:suite) do
    FactoryBot.find_definitions
  end
end
