# frozen_string_literal: true

require 'simplecov'

SimpleCov.start do
  enable_coverage :branch
  primary_coverage :branch
  add_filter '/spec/'
  add_filter '/lib/coinbase/client/'
end

require_relative '../lib/coinbase'
