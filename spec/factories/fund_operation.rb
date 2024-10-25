# frozen_string_literal: true

FUND_OPERATION_STATES = %i[pending complete failed].freeze

FactoryBot.define do
  factory :fund_operation_model, class: Coinbase::Client::FundOperation do
    transient do
      key { build(:key) }
      whole_amount { 123 }
      buy_fee { build(:fiat_amount_model) }
      transfer_fee { build(:crypto_amount_model, Coinbase.to_sym(network_id)) }
    end

    wallet_id { SecureRandom.uuid }
    fund_operation_id { SecureRandom.uuid }
    address_id { key.address.to_s }
    crypto_amount { build(:crypto_amount_model, Coinbase.to_sym(network_id), whole_amount: whole_amount) }

    fiat_amount { build(:fiat_amount_model) }

    # Default traits
    base_sepolia
    eth
    pending

    FUND_OPERATION_STATES.each do |status|
      trait status do
        status { status.to_s }
      end
    end

    NETWORK_TRAITS.each do |network|
      trait network do
        network_id { Coinbase.normalize_network(network) }
      end
    end

    ASSET_TRAITS.each do |asset|
      trait asset do
        crypto_amount do
          build(:crypto_amount_model, Coinbase.to_sym(network_id), asset, whole_amount: whole_amount)
        end
      end
    end

    after(:build) do |fund_operation, transients|
      transients.transfer_fee.asset.network_id = transients.network_id
      fund_operation.fees = Coinbase::Client::FundOperationFees.new(
        buy_fee: transients.buy_fee,
        transfer_fee: transients.transfer_fee
      )
    end
  end

  factory :fund_operation, class: Coinbase::FundOperation do
    initialize_with { new(model) }

    transient do
      network { nil }
      asset { nil }
      status { nil }
      key { build(:key) }
      amount { nil }
      fiat_amount { build(:fiat_amount_model) }
    end

    model { build(:fund_operation_model, key: key, crypto_amount: amount) }

    FUND_OPERATION_STATES.each do |status|
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
      transients.amount = build(:crypto_amount_model, network, whole_amount: 123) if transients.amount.nil?

      transfer.model do
        build(
          :fund_operation_model,
          transients,
          **{
            key: transients.key,
            crypto_amount: transients.amount,
            fiat_amount: transients.fiat_amount
          }.compact
        )
      end
    end
  end
end
