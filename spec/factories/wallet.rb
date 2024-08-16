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
      network_trait { nil }
    end

    initialize_with { Coinbase::Wallet.new(model, seed: seed) }

    model { build(:wallet_model, id: id) }

    # Register traits to enable passing through to wallet model factory.
    %i[without_default_address server_signer_pending server_signer_active].each do |trait_name|
      trait(trait_name { model.traits[trait_name] = true })
    end

    before(:build) do |_wallet, transients|
      transfer.model do
        build(:wallet_model, transients, id: id)
      end
    end
  end
end
