# frozen_string_literal: true

FactoryBot.define do
  factory :sponsored_send_model, class: Coinbase::Client::SponsoredSend do
    # Default trait.
    pending

    trait :pending do
      status { 'pending' }
      typed_data_hash { '0x7523946e17c0b8090ee18c84d6f9a8d63bab4d579a6507f0998dde0791891823' }
    end

    trait :signed do
      status { 'signed' }

      signature do
        '0x2f72103b6c803dd64a681874afd13d8a946274c075b4d547f910836223564858222840424da7bb5ef49d9a1047' \
          '54d6ddc9b2fc49447be05e89b77d6e41c9fbad1c'
      end
    end

    trait :submitted do
      signed
      status { 'submitted' }
    end

    # Create this alias for compatibility with enumerating TX_TRAITS
    trait :broadcasted do
      submitted
    end

    trait :completed do
      broadcasted
      status { 'complete' }
      transaction_hash { '0xdea671372a8fff080950d09ad5994145a661c8e95a9216ef34772a19191b5690' }
      transaction_link { "https://sepolia.basescan.org/tx/#{transaction_hash}" }
    end

    trait :failed do
      broadcasted
      status { 'failed' }
      transaction_hash { '0xdea671372a8fff080950d09ad5994145a661c8e95a9216ef34772a19191b5690' }
      transaction_link { "https://sepolia.basescan.org/tx/#{transaction_hash}" }
    end
  end

  factory :sponsored_send, class: Coinbase::SponsoredSend do
    initialize_with { new(model) }
    model { build(:sponsored_send_model) }

    (TX_TRAITS + %i[submitted]).each do |status|
      trait status do
        model { build(:sponsored_send_model, status) }
      end
    end
  end
end
