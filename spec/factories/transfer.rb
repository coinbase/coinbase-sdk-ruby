# frozen_string_literal: true

FactoryBot.define do
  factory :transfer_model, class: Coinbase::Client::Transfer do
    transient do
      key { build(:key) }
      to_key { build(:key, :destination) }
      whole_amount { 123 }
      gasless { false }
      status { 'pending' }
    end

    wallet_id { SecureRandom.uuid }
    transfer_id { SecureRandom.uuid }
    address_id { key.address.to_s }
    destination { to_key.address.to_s }
    amount { nil } # Can be explicitly set or defaults to using whole_amount.

    # Default traits
    base_sepolia
    eth
    pending

    trait :gasless do
      gasless { true }
    end

    TX_TRAITS.each do |status|
      trait status do
        status { status }
      end
    end

    NETWORK_TRAITS.each do |network|
      trait network do
        network_id { Coinbase.normalize_network(network) }
      end
    end

    ASSET_TRAITS.each do |asset|
      trait asset do
        asset { build(:asset_model, asset, Coinbase.to_sym(network_id)) }
        asset_id { asset }
      end
    end

    after(:build) do |transfer, transients|
      # Set the atomic amount based on the whole amount,
      # if amount is not set and whole amount is set.
      if transfer.amount.nil? && !transients.whole_amount.nil?
        transfer.amount = Coinbase::Asset.from_model(transfer.asset)
                                         .to_atomic_amount(transients.whole_amount)
                                         .to_s
      end

      if transients.gasless
        transfer.sponsored_send = build(:sponsored_send_model, transients.status)
      else
        transfer.transaction = build(:transaction_model, transients.status)
      end
    end
  end

  factory :transfer, class: Coinbase::Transfer do
    initialize_with { new(model) }

    transient do
      network { nil }
      status { nil }
      asset { nil }
      key { build(:key) }
      to_key { build(:key, :destination) }
      whole_amount { nil }
    end

    model { build(:transfer_model, key: key, to_key: to_key, whole_amount: whole_amount) }

    TX_TRAITS.each do |status|
      trait status do
        status { status }
      end
    end

    NETWORK_TRAITS.each do |network|
      trait network do
        network { network }
      end
    end

    ASSET_TRAITS.each do |asset|
      trait asset do
        asset { asset }
      end
    end

    before(:build) do |transfer, transients|
      transfer.model do
        build(
          :transfer_model,
          transients,
          **{
            key: transients.key,
            to_key: transients.to_key,
            whole_amount: transients.whole_amount
          }.compact
        )
      end
    end
  end
end
