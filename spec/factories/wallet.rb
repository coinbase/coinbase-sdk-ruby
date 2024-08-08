# frozen_string_literal: true

FactoryBot.define do
  factory :wallet_model, class: Coinbase::Client::Wallet do
    transient do
      seed { '000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f' }
    end

    id { SecureRandom.uuid }
    default_address { build(:address_model, :with_seed, seed: seed, wallet_id: id) }

    # Default traits
    base_sepolia

    NETWORK_TRAITS.each do |network|
      trait network do
        network_id { Coinbase.normalize_network(network) }
      end
    end

    trait :without_default_address do
      default_address { nil }
    end

    trait :server_signer_pending do
      server_signer_status { 'pending_seed_creation' }
    end

    trait :server_signer_active do
      server_signer_status { 'active_seed' }
    end
  end

  factory :wallet, class: Coinbase::Wallet do
    transient do
      seed { '000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f' }
      id { SecureRandom.uuid }
    end

    initialize_with { new(model, seed: seed) }

    model { build(:wallet_model, id: id) }
  end
end
