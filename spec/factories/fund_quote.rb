# frozen_string_literal: true

FactoryBot.define do
  factory :fund_quote_model, class: Coinbase::Client::FundQuote do
    transient do
      key { build(:key) }
      whole_amount { 123 }
      buy_fee { build(:fiat_amount_model) }
      transfer_fee { build(:crypto_amount_model, Coinbase.to_sym(network_id)) }
    end

    wallet_id { SecureRandom.uuid }
    fund_quote_id { SecureRandom.uuid }
    address_id { key.address.to_s }
    crypto_amount { build(:crypto_amount_model, Coinbase.to_sym(network_id), whole_amount: whole_amount) }

    fiat_amount { build(:fiat_amount_model) }

    # Default traits
    base_sepolia
    eth

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

    after(:build) do |fund_quote, transients|
      transients.transfer_fee.asset.network_id = transients.network_id
      fund_quote.fees = Coinbase::Client::FundOperationFees.new(
        buy_fee: transients.buy_fee,
        transfer_fee: transients.transfer_fee
      )
    end
  end

  factory :fund_quote, class: Coinbase::FundQuote do
    initialize_with { new(model) }

    transient do
      network { base_sepolia }
      asset { nil }
      key { build(:key) }
      amount { nil }
      fiat_amount { build(:fiat_amount_model) }
    end

    model { build(:fund_quote_model, key: key, crypto_amount: amount) }

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
        transients.amount = build(:crypto_amount_model, network, whole_amount: 123) if transients.amount.nil?

        build(
          :fund_quote_model,
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
