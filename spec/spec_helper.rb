# frozen_string_literal: true

require 'simplecov'
require 'pry'

SimpleCov.start do
  enable_coverage :branch
  primary_coverage :branch
  add_filter '/spec/'
  add_filter '/lib/coinbase/client/'
end

require_relative '../lib/coinbase'
require_relative 'support/shared_examples/address_balances'
require_relative 'support/shared_examples/pagination'
