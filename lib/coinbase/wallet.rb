# frozen_string_literal: true

require 'money-tree'

module Coinbase
  # A crypto wallet.
  class Wallet
    def initialize
      @master = MoneyTree::Master.new
      @network_id = :bitcoin_testnet
      @addresses = []

      first_address = @master.node_for_path('m/44h/0h/0h/0/0')
      @addresses << first_address.to_address
    end

    # Returns the list of addresses in the Wallet.
    # @return [Array<String>] The list of addresses
    def list_addresses
      @addresses
    end
  end
end
