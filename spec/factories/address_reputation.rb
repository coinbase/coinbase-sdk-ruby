# frozen_string_literal: true

FactoryBot.define do
  factory :address_reputation_model, class: Coinbase::Client::AddressReputation do
    score { 50 }
    metadata do
      {
        total_transactions: 1,
        unique_days_active: 1,
        longest_active_streak: 1,
        current_active_streak: 2,
        activity_period_days: 3,
        bridge_transactions_performed: 4,
        lend_borrow_stake_transactions: 5,
        ens_contract_interactions: 6,
        smart_contract_deployments: 7,
        token_swaps_performed: 8
      }
    end

    initialize_with { new(attributes) }
  end

  factory :address_reputation, class: Coinbase::AddressReputation do
    transient do
      score { nil }
      metadata { nil }

      model do
        build(
          :address_reputation_model,
          { score: score, metadata: metadata }.compact
        )
      end
    end

    initialize_with { Coinbase::AddressReputation.new(model) }
  end
end
