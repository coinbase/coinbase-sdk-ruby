# frozen_string_literal: true

FactoryBot.define do
  factory :staking_balance_model, class: Coinbase::Client::StakingBalance do
    transient do
      network_trait { nil }
    end

    base_sepolia

    date { Time.now }
    address { '0xdeadbeef' }
    bonded_stake { build(:balance_model, network_trait) }
    unbonded_balance { build(:balance_model, network_trait) }
    participant_type { 'validator' }

    NETWORK_TRAITS.each do |network|
      trait network do
        network_trait { network }
      end
    end
  end

  factory :staking_balance, class: Coinbase::StakingBalance do
    transient do
      network_trait { nil }
      model { build(:staking_balance_model) }
    end

    initialize_with { new(model) }

    NETWORK_TRAITS.each do |network|
      trait network do
        network_trait { network }
      end
    end

    before(:build) do |_, transients|
      model do
        build(:staking_balance_model, transients)
      end
    end
  end
end
