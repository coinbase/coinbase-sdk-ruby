# frozen_string_literal: true

FactoryBot.define do
  factory :historical_balance_model, class: Coinbase::Client::HistoricalBalance do
    transient do
      network_id { nil }
      whole_amount { 1 }
    end

    block_hash { 'default_block_hash' }
    block_height { '123' }

    # Default traits
    base_sepolia
    eth

    amount { nil }

    NETWORK_TRAITS.each do |network|
      trait network do
        network_id { Coinbase.normalize_network(network) }
      end
    end

    ASSET_TRAITS.each do |asset|
      trait asset do
        asset { build(:asset_model, asset) }
      end
    end

    after(:build) do |historical_balance, transients|
      historical_balance.asset.network_id = transients.network_id

      # Set the atomic amount based on the whole amount,
      # if amount is not set and whole amount is set.
      if historical_balance.amount.nil? && !transients.whole_amount.nil?
        historical_balance.amount = Coinbase::Asset.from_model(historical_balance.asset)
                                                   .to_atomic_amount(transients.whole_amount)
                                                   .to_s
      end
    end
  end
end
