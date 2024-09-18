# frozen_string_literal: true

FactoryBot.define do
  factory :smart_contract_model, class: Coinbase::Client::SmartContract do
    transient do
      key { build(:key) }
      status { 'pending' }

      # Options for configuring smart contract.
      name { 'Test Token' }
      symbol { 'TT' }
      total_supply { 1_000 }
    end

    deployer_address { key.address.to_s }
    wallet_id { SecureRandom.uuid }
    smart_contract_id { SecureRandom.uuid }

    # Default traits
    base_sepolia
    pending
    token

    contract_address { '0x5FbDB2315678afecb367f032d93F642f64180aa3' }
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

    trait :token do
      options do
        Coinbase::Client::TokenContractOptions.new(
          name: name,
          symbol: symbol,
          total_supply: BigDecimal(total_supply).to_i.to_s
        )
      end
    end

    trait :nft do
      options do
        Coinbase::Client::NFTContractOptions.new(
          name: name,
          symbol: symbol
        )
      end
    end

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
      invocation.transaction = build(:transaction_model, transients.status, key: transients.key)
    end
  end

  factory :smart_contract, class: Coinbase::SmartContract do
    initialize_with { new(model) }

    transient do
      network { nil }
      status { nil }
      key { build(:key) }
      type { :token }
    end

    model { build(:smart_contract_model, type, key: key) }

    trait :token do
      type { :token }
    end

    trait :nft do
      type { :nft }
    end

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
          :smart_contract_model,
          transients,
          **{ key: transients.key }.compact
        )
      end
    end
  end
end
