# frozen_string_literal: true

describe Coinbase::WalletAddress do
  subject(:address) do
    described_class.new(model, key)
  end

  let(:key) { build(:key) }
  let(:network_id) { :base_sepolia }
  let(:normalized_network_id) { 'base-sepolia' }
  let(:network) { build(:network, network_id) }
  let(:address_id) { key.address.to_s }
  let(:model) { build(:address_model, network_id) }
  let(:wallet_id) { model.wallet_id }
  let(:addresses_api) { instance_double(Coinbase::Client::ExternalAddressesApi) }

  before do
    allow(Coinbase::Client::ExternalAddressesApi).to receive(:new).and_return(addresses_api)

    allow(Coinbase::Network)
      .to receive(:from_id)
      .with(satisfy { |id| id == network_id || id == normalized_network_id })
      .and_return(network)
  end

  describe '#initialize' do
    it 'initializes a new Address' do
      expect(address).to be_a(described_class)
    end
  end

  describe '#network' do
    it 'returns the network' do
      expect(address.network).to eq(network)
    end
  end

  describe '#id' do
    it 'returns the address ID' do
      expect(address.id).to eq(address_id)
    end
  end

  describe '#wallet_id' do
    it 'returns the wallet ID' do
      expect(address.wallet_id).to eq(wallet_id)
    end
  end

  describe '#key=' do
    let(:unhydrated_address) { described_class.new(model, nil) }

    it 'sets the key' do
      expect { unhydrated_address.key = key }.not_to raise_error
    end

    it 'raises an error if the key is already set' do
      expect { address.key = key }.to raise_error('Private key is already set')
    end
  end

  describe '#can_sign?' do
    it 'returns true if the address has a key' do
      expect(address.can_sign?).to be true
    end

    it 'returns false if the address does not have a key' do
      unhydrated_address = described_class.new(model, nil)
      expect(unhydrated_address.can_sign?).to be false
    end
  end

  describe '#export' do
    let(:private_key) { key.private_hex }

    it 'exports the private key from address' do
      expect(address.export).to eq(private_key)
    end

    context 'when the address is unhydrated' do
      let(:unhydrated_address) { described_class.new(model, nil) }

      it 'raises an error' do
        expect do
          unhydrated_address.export
        end.to raise_error('Cannot export key without private key loaded')
      end
    end
  end

  describe '#inspect' do
    it 'includes address details' do
      expect(address.inspect).to include(address_id, Coinbase.to_sym(network_id).to_s, wallet_id)
    end

    it 'returns the same value as to_s' do
      expect(address.inspect).to eq(address.to_s)
    end
  end

  it_behaves_like 'an address that supports balance queries'
  it_behaves_like 'an address that supports requesting faucet funds'
  it_behaves_like 'an address that supports staking'

  describe '#invoke_contract' do
    subject(:contract_invocation) do
      address.invoke_contract(
        contract_address: contract_invocation_model.contract_address,
        method: contract_invocation_model.method,
        abi: abi,
        args: args
      )
    end

    let(:contract_invocation_model) { build(:contract_invocation_model) }
    let(:abi) { JSON.parse(contract_invocation_model.abi) }
    let(:args) { JSON.parse(contract_invocation_model.args) }
    let(:use_server_signer) { false }
    let(:created_invocation) { build(:contract_invocation, network_id, key: key) }

    before do
      allow(Coinbase).to receive(:use_server_signer?).and_return(use_server_signer)
    end

    context 'when the contract invocation is successful' do
      before do
        allow(Coinbase::ContractInvocation).to receive(:create).and_return(created_invocation)

        allow(created_invocation).to receive(:sign)
        allow(created_invocation).to receive(:broadcast!)

        contract_invocation
      end

      it 'creates a contract invocation' do # rubocop:disable RSpec/ExampleLength
        expect(Coinbase::ContractInvocation).to have_received(:create).with(
          address_id: address_id,
          wallet_id: wallet_id,
          contract_address: contract_invocation_model.contract_address,
          method: contract_invocation_model.method,
          abi: abi,
          amount: nil,
          asset_id: nil,
          network: network,
          args: args
        )
      end

      it 'returns the created contract invocation' do
        expect(contract_invocation).to eq(created_invocation)
      end

      context 'when not using server signer' do
        let(:use_server_signer) { false }

        it 'signs the transaction with the key' do
          expect(created_invocation).to have_received(:sign).with(key)
        end

        it 'broadcasts the transfer' do
          expect(created_invocation).to have_received(:broadcast!)
        end
      end

      context 'when using server signer' do
        let(:use_server_signer) { true }

        it 'does not sign the transaction with the key' do
          expect(created_invocation).not_to have_received(:sign)
        end

        it 'does not broadcast the transfer' do
          expect(created_invocation).not_to have_received(:broadcast!)
        end
      end
    end

    context 'when invoking a payable contract method' do
      subject(:contract_invocation) do
        address.invoke_contract(
          contract_address: contract_invocation_model.contract_address,
          method: contract_invocation_model.method,
          abi: abi,
          args: args,
          amount: 100,
          asset_id: :wei
        )
      end

      let(:balance) { 1_000 }
      let(:created_invocation) { build(:contract_invocation, network_id, key: key, amount: '100') }

      before do
        allow(addresses_api)
          .to receive(:get_external_address_balance)
          .with(normalized_network_id, address_id, 'eth')
          .and_return(build(:balance_model, network_id, whole_amount: balance))

        allow(Coinbase::ContractInvocation).to receive(:create).and_return(created_invocation)

        allow(created_invocation).to receive(:sign)
        allow(created_invocation).to receive(:broadcast!)

        contract_invocation
      end

      it 'creates a contract invocation' do # rubocop:disable RSpec/ExampleLength
        expect(Coinbase::ContractInvocation).to have_received(:create).with(
          address_id: address_id,
          wallet_id: wallet_id,
          contract_address: contract_invocation_model.contract_address,
          method: contract_invocation_model.method,
          abi: abi,
          amount: 100,
          asset_id: :wei,
          network: network,
          args: args
        )
      end

      it 'returns the created contract invocation' do
        expect(contract_invocation).to eq(created_invocation)
      end
    end
  end

  describe '#transfer' do
    subject(:transfer) { address.transfer(amount, asset_id, to_address_id) }

    let(:balance) { 1_000 }
    let(:amount) { 500 }
    let(:to_key) { Eth::Key.new }
    let(:to_address_id) { to_key.address.to_s }
    let(:asset_id) { :eth }
    let(:created_transfer) { build(:transfer, network_id, key: key, to_key: to_key) }
    let(:use_server_signer) { false }

    before do
      allow(Coinbase).to receive(:use_server_signer?).and_return(use_server_signer)

      allow(addresses_api)
        .to receive(:get_external_address_balance)
        .with(normalized_network_id, address_id, 'eth')
        .and_return(build(:balance_model, network_id, whole_amount: balance))
    end

    context 'when the transfer is successful' do
      before do
        allow(Coinbase::Transfer).to receive(:create).and_return(created_transfer)

        allow(created_transfer).to receive(:sign)
        allow(created_transfer).to receive(:broadcast!)

        transfer
      end

      context 'when not using server signer' do
        let(:use_server_signer) { false }

        it 'returns the created transfer' do
          expect(transfer).to eq(created_transfer)
        end

        it 'signs the transaction with the key' do
          expect(created_transfer).to have_received(:sign).with(key)
        end

        it 'broadcasts the transfer' do
          expect(created_transfer).to have_received(:broadcast!)
        end
      end

      context 'when using server signer' do
        let(:use_server_signer) { true }

        it 'returns the created transfer' do
          expect(transfer).to eq(created_transfer)
        end

        it 'creates the transfer' do
          expect(Coinbase::Transfer).to have_received(:create).with(
            address_id: address_id,
            amount: amount,
            asset_id: asset_id,
            destination: to_address_id,
            network: network,
            wallet_id: wallet_id,
            gasless: false
          )
        end

        it 'does not broadcast the transfer' do
          expect(created_transfer).not_to have_received(:broadcast!)
        end

        it 'does not sign the transaction with the key' do
          expect(created_transfer).not_to have_received(:sign)
        end
      end
    end

    context 'when the balance is insufficient' do
      let(:amount) { balance + 10 }

      it 'raises an InsufficientFundsError' do
        expect do
          address.transfer(amount, asset_id, to_address_id)
        end.to raise_error(Coinbase::InsufficientFundsError)
      end
    end

    context 'when the address cannot sign' do
      let(:unhydrated_address) { described_class.new(model, nil) }

      it 'raises an AddressCannotSignError' do
        expect do
          unhydrated_address.transfer(1, :wei, to_address_id)
        end.to raise_error(Coinbase::AddressCannotSignError)
      end
    end
  end

  describe '#trade' do
    subject(:trade) { address.trade(amount, from_asset_id, to_asset_id) }

    let(:balance) { 1_000 }
    let(:amount) { 500 }
    let(:transactions) do
      [
        instance_double(Coinbase::Transaction, sign: 'signed_payload'),
        instance_double(Coinbase::Transaction, sign: 'approve_signed_payload')
      ]
    end
    let(:created_trade) do
      instance_double(Coinbase::Trade, id: SecureRandom.uuid, transactions: transactions)
    end
    let(:from_asset_id) { :eth }
    let(:normalized_from_asset_id) { 'eth' }
    let(:to_asset_id) { :usdc }
    let(:use_server_signer) { false }

    before do
      allow(addresses_api)
        .to receive(:get_external_address_balance)
        .with(normalized_network_id, address_id, normalized_from_asset_id)
        .and_return(build(:balance_model, network_id, :eth, whole_amount: balance))

      allow(Coinbase).to receive(:use_server_signer?).and_return(use_server_signer)
    end

    context 'when the trade is successful' do
      let(:from_asset_id) { :eth }
      let(:amount) { 0.5 }

      before do
        allow(Coinbase::Trade).to receive(:create).and_return(created_trade)

        allow(created_trade).to receive(:broadcast!)

        trade
      end

      context 'when not using server signer' do
        let(:use_server_signer) { false }

        it 'returns the created trade' do
          expect(trade).to eq(created_trade)
        end

        it 'creates the trade' do
          expect(Coinbase::Trade).to have_received(:create).with(
            address_id: address_id,
            amount: amount,
            from_asset_id: from_asset_id,
            to_asset_id: to_asset_id,
            network: network,
            wallet_id: wallet_id
          )
        end

        it 'signs all of the transactions with the address key' do
          expect(transactions).to all have_received(:sign).with(key)
        end

        it 'broadcasts the trade' do
          expect(created_trade).to have_received(:broadcast!)
        end
      end

      context 'when using server signer' do
        let(:use_server_signer) { true }

        it 'returns the created trade' do
          expect(trade).to eq(created_trade)
        end

        it 'creates the trade' do
          expect(Coinbase::Trade).to have_received(:create).with(
            address_id: address_id,
            amount: amount,
            from_asset_id: from_asset_id,
            to_asset_id: to_asset_id,
            network: network,
            wallet_id: wallet_id
          )
        end

        it 'does not broadcast the trade' do
          expect(created_trade).not_to have_received(:broadcast!)
        end

        it 'signs none of the transactions with the address key' do
          transactions.each do |transaction|
            expect(transaction).not_to have_received(:sign)
          end
        end
      end
    end

    context 'when the balance is insufficient' do
      let(:amount) { balance + 10 }

      it 'raises an InsufficientFundsError' do
        expect do
          address.trade(amount, from_asset_id, to_asset_id)
        end.to raise_error(Coinbase::InsufficientFundsError)
      end

      it 'does not sign any transaction' do
        transactions.each do |tx|
          expect(tx).not_to have_received(:sign)
        end
      end
    end

    describe 'when the address cannot sign' do
      let(:unhydrated_address) { described_class.new(model, nil) }

      it 'raises an AddressCannotSignError' do
        expect do
          unhydrated_address.trade(12_345, from_asset_id, to_asset_id)
        end.to raise_error(Coinbase::AddressCannotSignError)
      end

      it 'does not sign any transaction' do
        transactions.each do |tx|
          expect(tx).not_to have_received(:sign)
        end
      end
    end
  end

  describe '#sign_payload' do
    subject(:payload_signature) { address.sign_payload(unsigned_payload: unsigned_payload) }

    let(:payload_signature_id) { SecureRandom.uuid }
    let(:signing_key) { build(:key) }
    let(:address_id) { signing_key.address.to_s }
    let(:pending_payload_signature_model) do
      build(:payload_signature_model, :pending, key: signing_key, wallet_id: wallet_id,
                                                payload_signature_id: payload_signature_id)
    end
    let(:signed_payload_signature_model) do
      build(:payload_signature_model, :signed, key: signing_key, wallet_id: wallet_id,
                                               payload_signature_id: payload_signature_id)
    end
    let(:pending_payload_signature) { Coinbase::PayloadSignature.new(pending_payload_signature_model) }
    let(:signed_payload_signature) { Coinbase::PayloadSignature.new(signed_payload_signature_model) }
    let(:unsigned_payload) { pending_payload_signature_model.unsigned_payload }
    let(:signature) { signed_payload_signature_model.signature }
    let(:use_server_signer) { false }

    before do
      allow(Coinbase).to receive(:use_server_signer?).and_return(use_server_signer)
    end

    context 'when not using server signer' do
      let(:use_server_signer) { false }

      before do
        allow(Coinbase::PayloadSignature).to receive(:create).and_return(signed_payload_signature)

        payload_signature
      end

      it 'returns the payload signature' do
        expect(payload_signature).to eq(signed_payload_signature)
      end

      it 'creates the payload signature' do
        expect(Coinbase::PayloadSignature).to have_received(:create).with(
          wallet_id: wallet_id,
          address_id: address_id,
          unsigned_payload: unsigned_payload,
          signature: signature
        )
      end
    end

    context 'when using server signer' do
      let(:use_server_signer) { true }

      before do
        allow(Coinbase::PayloadSignature).to receive(:create).and_return(pending_payload_signature)

        payload_signature
      end

      it 'returns the pending payload signature' do
        expect(payload_signature).to eq(pending_payload_signature)
      end

      it 'creates the payload signature' do
        expect(Coinbase::PayloadSignature).to have_received(:create).with(
          wallet_id: wallet_id,
          address_id: address_id,
          unsigned_payload: unsigned_payload,
          signature: nil
        )
      end
    end

    describe 'when the address cannot sign' do
      let(:unhydrated_address) { described_class.new(model, nil) }

      it 'raises an AddressCannotSignError' do
        expect do
          unhydrated_address.sign_payload(unsigned_payload: unsigned_payload)
        end.to raise_error(Coinbase::AddressCannotSignError)
      end
    end
  end

  shared_examples 'an address that can do a staking_action' do |operation|
    subject(:action) { address.send(operation.to_sym, amount, asset_id, mode: mode) }

    include_context 'with mocked staking_balances'
    let(:amount) { 1 }
    let(:mode) { :default }
    let(:asset_id) { :eth }
    let(:staking_operation) { instance_double(Coinbase::StakingOperation, id: 'test-id') }
    let(:transaction) { instance_double(Coinbase::Transaction) }

    before do
      allow(Coinbase::StakingOperation).to receive(:create).and_return(staking_operation)
      allow(staking_operation).to receive(:complete)

      action
    end

    it 'creates a staking operation' do
      expect(Coinbase::StakingOperation).to have_received(:create).with(
        amount,
        network,
        asset_id,
        address_id,
        wallet_id,
        operation,
        mode,
        {}
      )
    end

    it 'completes the operation' do
      expect(staking_operation).to have_received(:complete).with(key, anything)
    end
  end

  describe '#stake' do
    it_behaves_like 'an address that can do a staking_action', 'stake'
  end

  describe '#unstake' do
    it_behaves_like 'an address that can do a staking_action', 'unstake'
  end

  describe '#claim_stake' do
    it_behaves_like 'an address that can do a staking_action', 'claim_stake'
  end

  describe '#transfers' do
    let(:transfer_enumerator) { instance_double(Enumerator) }

    before do
      allow(Coinbase::Transfer)
        .to receive(:list)
        .with(wallet_id: wallet_id, address_id: address_id)
        .and_return(transfer_enumerator)
    end

    it 'lists the transfers' do
      expect(address.transfers).to eq(transfer_enumerator)
    end
  end

  describe '#trades' do
    let(:trade_enumerator) { instance_double(Enumerator) }

    before do
      allow(Coinbase::Trade)
        .to receive(:list)
        .with(wallet_id: wallet_id, address_id: address_id)
        .and_return(trade_enumerator)
    end

    it 'lists the trades' do
      expect(address.trades).to eq(trade_enumerator)
    end
  end
end
