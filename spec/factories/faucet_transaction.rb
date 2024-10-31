# frozen_string_literal: true

FactoryBot.define do
  factory :faucet_tx_model, class: Coinbase::Client::FaucetTransaction do
    transient do
      status { 'broadcasted' }
      network_trait { :base_sepolia }
      to_address_id { nil }
      transaction_hash { nil }
    end

    # Default traits
    base_sepolia
    pending

    TX_TRAITS.each do |status|
      trait status do
        status { status }
      end
    end

    NETWORK_TRAITS.each do |network|
      trait network do
        network_trait { network }
      end
    end

    after(:build) do |transfer, transients|
      transfer.transaction = build(
        :transaction_model,
        transients.status,
        transients.network_trait,
        {
          to_address_id: transients.to_address_id,
          transaction_hash: transients.transaction_hash
        }.compact
      )
    end
  end
end
