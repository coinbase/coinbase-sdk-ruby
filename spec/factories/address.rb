# frozen_string_literal: true

FactoryBot.define do
  factory :address_model, class: Coinbase::Client::Address do
    network_id { 'base-sepolia' }

    transient do
      key { build(:key) }
    end

    address_id { key.address.to_s }
    public_key { key.public_key.compressed.unpack1('H*') }
    wallet_id { SecureRandom.uuid }

    trait :ethereum_mainnet do
      network_id { 'ethereum-mainnet' }
    end

    trait :ethereum_holesky do
      network_id { 'ethereum-holesky' }
    end

    trait :base_mainnet do
      network_id { 'base-mainnet' }
    end

    trait :base_sepolia do
      network_id { 'base-sepolia' }
    end
  end
end
