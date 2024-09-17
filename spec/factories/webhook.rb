# frozen_string_literal: true

FactoryBot.define do
  factory :webhook_model, class: 'Coinbase::Client::Webhook' do
    id { 'webhook_id' }
    network_id { :base_sepolia }
    event_type { 'erc20_transfer' }
    event_filters { [{ 'contract_address' => '0x833589fcd6edb6e08f4c7c32d4f71b54bda02913' }] }
    notification_uri { 'https://example.com/notify' }
    signature_header { 'example_header' }
    event_type_filter do
      {
        'addresses' => ['0xa3B299855BE3eA231337aC7c40A615e090A3de25'],
        'wallet_id' => 'd91d652b-d020-48d4-bf19-5c5eb5e280c7'
      }
    end

    trait :updated_uri do
      notification_uri { build(:notification_uri) }
    end

    trait :wallet_activity do
      id { 'wallet_webhook' }
      event_type { 'wallet_activity' }
      notification_uri { 'https://example.com/notify' }
      event_type_filter do
        {
          'addresses' => ['0xa3B299855BE3eA231337aC7c40A615e090A3de25'],
          'wallet_id' => 'd91d652b-d020-48d4-bf19-5c5eb5e280c7'
        }
      end
    end
  end

  factory :webhook, class: 'Coinbase::Webhook' do
    transient do
      model { build(:webhook_model) }
    end

    initialize_with { new(model) }
  end
end
