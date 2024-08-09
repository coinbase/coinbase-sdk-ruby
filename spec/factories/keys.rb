# frozen_string_literal: true

FactoryBot.define do
  factory :key, class: Eth::Key do
    initialize_with { new(priv: priv) }

    transient do
      seed { nil }
      index { 0 }
    end

    priv { '0233b43978845c03783510106941f42370e0f11022b0c3b717c0791d046f4536' }

    trait :destination do
      priv { '3d560ef7d3368b419ed806b12a8c240b299ef1215d04d8042f7b3e60aae17771' }
    end

    trait :with_seed do
      priv do
        MoneyTree::Master.new(seed_hex: seed)
                         .node_for_path("m/44'/60'/0'/0/#{index}")
                         .private_key
                         .to_hex
      end
    end
  end
end
