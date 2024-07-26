# frozen_string_literal: true

require 'date'

module Coinbase
  # A representation of a blockchain Address that do not belong to a Coinbase::Wallet.
  # External addresses can be used to fetch balances, request funds from the faucet, etc...,
  # but cannot be used to sign transactions.
  class ExternalAddress < Address; end
end
