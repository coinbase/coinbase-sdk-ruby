# frozen_string_literal: true

FactoryBot.define do
  factory :staking_balance_model, class: Coinbase::Client::StakingBalance do
    date { Time.now }
    address { '0xdeadbeef' }
    bonded_stake { build(:balance_model) }
    unbonded_balance { build(:balance_model) }
    participant_type { 'validator' }
  end

  factory :staking_balance, class: Coinbase::StakingBalance do
    transient do
      model { build(:staking_balance_model) }
    end

    initialize_with { new(model) }
  end
end
