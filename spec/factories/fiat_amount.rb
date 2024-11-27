# frozen_string_literal: true

FactoryBot.define do
  factory :fiat_amount_model, class: Coinbase::Client::FiatAmount do
    amount { '1.23' }
    currency { 'usd' }
  end

  factory :fiat_amount, class: Coinbase::FiatAmount do
    initialize_with { Coinbase::FiatAmount.from_model(model) }

    transient do
      amount { '1.23' }
      currency { 'usd' }
    end

    model do
      build(:fiat_amount_model, amount: amount, currency: currency)
    end
  end
end
