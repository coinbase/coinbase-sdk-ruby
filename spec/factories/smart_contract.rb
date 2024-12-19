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
      base_uri { 'https://test.com' }
    end

    is_external { false }
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
      type { Coinbase::Client::SmartContractType::ERC20 }
      options do
        Coinbase::Client::TokenContractOptions.new(
          name: name,
          symbol: symbol,
          total_supply: BigDecimal(total_supply).to_i.to_s
        )
      end
      contract_name { name }
    end

    trait :nft do
      type { Coinbase::Client::SmartContractType::ERC721 }
      options do
        Coinbase::Client::NFTContractOptions.new(
          name: name,
          symbol: symbol,
          base_uri: base_uri
        )
      end
      contract_name { name }
    end

    trait :multi_token do
      type { Coinbase::Client::SmartContractType::ERC1155 }
      options do
        Coinbase::Client::MultiTokenContractOptions.new(
          uri: 'https://example.com/token/{id}.json'
        )
      end
    end

    trait :external do
      is_external { true }
      deployer_address { nil }
      wallet_id { nil }
      type { Coinbase::Client::SmartContractType::CUSTOM }
      options { nil }
      contract_name { 'External Contract' }
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
      unless invocation.is_external
        invocation.transaction = build(:transaction_model, transients.status, key: transients.key)
      end
    end
  end

  factory :smart_contract, class: Coinbase::SmartContract do
    initialize_with { new(model) }

    transient do
      network { nil }
      status { nil }
      key { build(:key) }
      type { :token }
      contract_address { '0x5FbDB2315678afecb367f032d93F642f64180aa3' }
    end

    model do
      build(:smart_contract_model, type, key: key, contract_address: contract_address)
    end

    trait :token do
      type { :token }
    end

    trait :nft do
      type { :nft }
    end

    trait :multi_token do
      type { :multi_token }
    end

    trait :external do
      type { :external }
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
          **{
            key: transients.key,
            contract_address: contract_address
          }.compact
        )
      end
    end
  end
end
