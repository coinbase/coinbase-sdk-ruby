# frozen_string_literal: true

FactoryBot.define do
  factory :payload_signature_model, class: Coinbase::Client::PayloadSignature do
    transient do
      key { build(:key) }
    end

    address_id { key.address.to_s }
    wallet_id { :wallet_id }
    payload_signature_id { :payload_signature_id }

    trait :pending do
      status { 'pending' }
      unsigned_payload { '0x58f51af4cb4775cebe5853f0bf1e984927415e889a3d55ae6d243aeec46ffd10' }
    end

    trait :signed do
      status { 'signed' }
      unsigned_payload { '0x58f51af4cb4775cebe5853f0bf1e984927415e889a3d55ae6d243aeec46ffd10' }
      signature do
        "0x#{key.sign(Eth::Util.hex_to_bin(unsigned_payload))}"
      end
    end

    trait :failed do
      status { 'failed' }
      unsigned_payload { '0x58f51af4cb4775cebe5853f0bf1e984927415e889a3d55ae6d243aeec46ffd10' }
    end
  end

  factory :payload_signature, class: Coinbase::PayloadSignature do
    initialize_with { new(:model) }

    PAYLOAD_SIGNATURE_TRAITS.each do |status|
      trait status do
        model { build(:payload_signature_model, status) }
      end
    end
  end
end
