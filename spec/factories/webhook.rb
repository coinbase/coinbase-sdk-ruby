# frozen_string_literal: true

FactoryBot.define do
  factory :webhook_model, class: 'Coinbase::Client::Webhook' do
    id { 'webhook_id' }
    network_id { :base_sepolia }
    event_type { 'erc20_transfer' }
    event_filters { [{ 'contract_address' => '0x833589fcd6edb6e08f4c7c32d4f71b54bda02913' }] }
    notification_uri { 'https://example.com/notify' }

    trait :updated_uri do
      notification_uri { build(:notification_uri) }
    end
  end

  factory :webhook, class: 'Coinbase::Webhook' do
    transient do
      model { build(:webhook_model) }
    end

    initialize_with { new(model) }
  end
end
