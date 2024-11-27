# frozen_string_literal: true

FactoryBot.define do
  factory :crypto_amount_model, class: Coinbase::Client::CryptoAmount do
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

    after(:build) do |crypto_amount, transients|
      crypto_amount.asset.network_id = transients.network_id

      # Set the atomic amount based on the whole amount,
      # if amount is not set and whole amount is set.
      if crypto_amount.amount.nil? && !transients.whole_amount.nil?
        crypto_amount.amount = Coinbase::Asset.from_model(crypto_amount.asset)
                                              .to_atomic_amount(BigDecimal(transients.whole_amount))
                                              .to_s
      end
    end
  end

  factory :crypto_amount, class: Coinbase::CryptoAmount do
    initialize_with { Coinbase::CryptoAmount.from_model(model) }

    transient do
      network_trait { nil }
      asset_trait { nil }
      whole_amount { 123 }
    end

    # Default traits.
    base_sepolia
    eth

    model do
      build(
        :crypto_amount_model,
        *[network_trait, asset_trait].compact,
        whole_amount: whole_amount
      )
    end

    NETWORK_TRAITS.each do |network|
      trait network do
        network_trait { network }
      end
    end

    ASSET_TRAITS.each do |asset|
      trait asset do
        asset_trait { asset }
      end
    end
  end
end
