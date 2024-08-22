# frozen_string_literal: true

FactoryBot.define do
  factory :network_model, class: Coinbase::Client::Network do
    # Default traits
    base_sepolia

    trait :base_sepolia do
      id { 'base_sepolia' }
      display_name { 'Base Sepolia' }
      protocol_family { 'evm' }
      is_testnet { true }
      native_asset { build(:asset_model, :eth, :base_sepolia) }
      chain_id { 84_532 }
      address_path_prefix { "m/44'/60'/0'/0" }
    end

    trait :base_mainnet do
      id { 'base-mainnet' }
      display_name { 'Base' }
      protocol_family { 'evm' }
      is_testnet { false }
      native_asset { build(:asset_model, :eth, :base_mainnet) }
      chain_id { 8_453 }
      address_path_prefix { "m/44'/60'/0'/0" }
    end

    trait :ethereum_mainnet do
      id { 'ethereum-mainnet' }
      display_name { 'Ethereum' }
      protocol_family { 'evm' }
      is_testnet { false }
      native_asset { build(:asset_model, :eth, :ethereum_mainnet) }
      chain_id { 1 }
      address_path_prefix { "m/44'/60'/0'/0" }
    end

    trait :ethereum_holesky do
      id { 'ethereum-holesky' }
      display_name { 'Ethereum Holesky' }
      protocol_family { 'evm' }
      is_testnet { true }
      native_asset { build(:asset_model, :eth, :ethereum_holesky) }
      chain_id { 17_000 }
      address_path_prefix { "m/44'/60'/0'/0" }
    end
  end

  factory :network, class: Coinbase::Network do
    transient do
      network_id { nil }
      model { nil }
    end

    initialize_with do
      Coinbase::Network.new(network_id).tap do |network|
        network.instance_variable_set(:@model, model)
      end
    end

    NETWORK_TRAITS.each do |trait|
      trait trait do
        network_id { Coinbase.to_sym(trait) }
        model { build(:network_model, trait) }
      end
    end
  end
end
