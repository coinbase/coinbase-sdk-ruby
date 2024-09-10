# frozen_string_literal: true

require 'spec_helper'

describe Coinbase::BalanceHistoryApi do
  subject(:address) { described_class.new(network_id, address_id) }

  let(:network) { build(:network, :ethereum_mainnet) }
  let(:network_id) { :ethereum_mainnet }
  let(:normalized_network_id) { 'ethereum-mainnet' }
  let(:address_id) { '0x1234' }

  it_behaves_like 'an address that supports balance queries'
end
