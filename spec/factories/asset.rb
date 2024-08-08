# frozen_string_literal: true

FactoryBot.define do
  factory :asset_model, class: Coinbase::Client::Asset do
    # Default traits
    base_sepolia
    eth

    trait :eth do
      asset_id { 'eth' }
      decimals { 18 }
    end

    trait :usdc do
      asset_id { 'usdc' }
      decimals { 6 }
      contract_address { '0x036CbD53842c5426634e7929541eC2318f3dCF7e' }
    end

    trait :weth do
      asset_id { 'weth' }
      decimals { 18 }
      contract_address { '0x4200000000000000000000000000000000000006' }
    end

    TEST_NETWORKS.each do |network|
      trait network do
        network_id { Coinbase.normalize_network(network) }
      end
    end
  end

  factory :asset, class: Coinbase::Asset do
    transient do
      asset_id { nil }
      model { build(:asset_model) }
    end

    initialize_with { Coinbase::Asset.from_model(model, asset_id: asset_id) }

    (%i[eth usdc weth] + TEST_NETWORKS).each do |trait|
      trait trait do
        model { build(:asset_model, trait) }
      end
    end

    trait :wei do
      asset_id { :wei }
    end

    trait :gwei do
      asset_id { :gwei }
    end
  end
end
