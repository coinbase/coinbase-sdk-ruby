# frozen_string_literal: true

FactoryBot.define do
  factory :address_model, class: Coinbase::Client::Address do
    network_id { 'base-sepolia' }

    transient do
      seed { nil }
      index { 0 }
      key { build(:key) }
    end

    address_id { key.address.to_s }
    public_key { key.public_key.compressed.unpack1('H*') }
    wallet_id { SecureRandom.uuid }

    trait :with_seed do
      key { build(:key, :with_seed, seed: seed, index: index) }
    end

    NETWORK_TRAITS.each do |network|
      trait network do
        network_id { Coinbase.normalize_network(network) }
      end
    end
  end
end
