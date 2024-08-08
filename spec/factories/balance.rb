# frozen_string_literal: true

FactoryBot.define do
  factory :balance_model, class: Coinbase::Client::Balance do
    transient do
      network_id { nil }
      whole_amount { 1 }
    end

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

    after(:build) do |balance, transients|
      balance.asset.network_id = transients.network_id

      # Set the atomic amount based on the whole amount,
      # if amount is not set and whole amount is set.
      if balance.amount.nil? && !transients.whole_amount.nil?
        balance.amount = Coinbase::Asset.from_model(balance.asset)
                                        .to_atomic_amount(transients.whole_amount)
                                        .to_s
      end
    end
  end
end
