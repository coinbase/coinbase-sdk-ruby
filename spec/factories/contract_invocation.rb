# frozen_string_literal: true

FactoryBot.define do
  factory :contract_invocation_model, class: Coinbase::Client::ContractInvocation do
    transient do
      key { build(:key) }
      status { 'pending' }
      amount { '0' }
    end

    address_id { key.address.to_s }
    wallet_id { SecureRandom.uuid }
    contract_invocation_id { SecureRandom.uuid }

    # Default traits
    base_sepolia
    pending

    contract_address { '0x5FbDB2315678afecb367f032d93F642f64180aa3' }
    add_attribute(:method) { 'mint' }
    abi do
      [
        {
          inputs: [{ internalType: 'address', name: 'recipient', type: 'address' }],
          name: 'mint',
          outputs: [{ internalType: 'uint256', name: '', type: 'uint256' }],
          stateMutability: 'payable',
          type: 'function'
        }
      ].to_json
    end
    args { { recipient: '0x475d41de7A81298Ba263184996800CBcaAD73C0b' }.to_json }

    NETWORK_TRAITS.each do |network|
      trait network do
        network_id { Coinbase.normalize_network(network) }
      end
    end

    TX_TRAITS.each do |status|
      trait status do
        status { status }
      end
    end

    after(:build) do |invocation, transients|
      invocation.transaction = build(:transaction_model, transients.status)
    end
  end

  factory :contract_invocation, class: Coinbase::ContractInvocation do
    initialize_with { new(model) }

    transient do
      network { nil }
      status { nil }
      key { build(:key) }
      amount { '0' }
    end

    model { build(:contract_invocation_model, key: key) }

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

    before(:build) do |invocation, transients|
      invocation.model do
        build(
          :contract_invocation_model,
          transients,
          **{ key: transients.key }.compact
        )
      end
    end
  end
end
