# frozen_string_literal: true

FactoryBot.define do
  factory :contract_event_model, class: 'Coinbase::Client::ContractEvent' do
    network_id { 'ethereum-mainnet' }
    protocol_name { 'uniswap' }
    contract_name { 'Pool' }
    event_name { 'Transfer' }
    sig { 'Transfer(address,address,uint256)' }
    four_bytes { '0xddf252ad' }
    contract_address { '0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48' }
    block_time { Time.now.iso8601 }
    block_height { 201_782_330 }
    tx_hash { '0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef' }
    tx_index { 109 }
    event_index { 362 }
    data { '{"from":"0x1234...","to":"0x5678...","value":"1000000000000000000"}' }
  end

  factory :contract_event, class: 'Coinbase::ContractEvent' do
    transient do
      model { build(:contract_event_model) }
    end

    initialize_with { new(model) }
  end
end
