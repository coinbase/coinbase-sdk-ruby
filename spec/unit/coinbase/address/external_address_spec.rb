# frozen_string_literal: true

describe Coinbase::ExternalAddress do
  let(:network_id) { :ethereum_mainnet }
  let(:normalized_network_id) { 'ethereum-mainnet' }
  let(:address_id) { '0x1234' }
  let(:external_addresses_api) { instance_double(Coinbase::Client::ExternalAddressesApi) }
  let(:stake_api) { instance_double(Coinbase::Client::StakeApi) }
  let(:id) { '0x1234' }
  let(:address) { described_class.new(network_id, id) }
  let(:eth_asset) do
    Coinbase::Client::Asset.new(network_id: normalized_network_id, asset_id: 'eth', decimals: 18)
  end
  let(:usdc_asset) do
    Coinbase::Client::Asset.new(network_id: normalized_network_id, asset_id: 'usdc', decimals: 6)
  end
  let(:weth_asset) do
    Coinbase::Client::Asset.new(network_id: normalized_network_id, asset_id: 'weth', decimals: 18)
  end
  let(:stake_balance) { 100 }
  let(:unstake_balance) { 100 }
  let(:claim_stake_balance) { 100 }
  let(:mode) { :partial }

  subject(:address) { described_class.new(network_id, address_id) }

  let(:staking_context) do
    instance_double(
      'Coinbase::Client::StakingContext',
      context: instance_double(
        'Coinbase::Client::StakingContext::Context',
        stakeable_balance: (stake_balance * 10**18).to_s,
        unstakeable_balance: (unstake_balance * 10**18).to_s,
        claimable_balance: (claim_stake_balance * 10**18).to_s
      )
    )
  end

  before(:each) do
    allow(Coinbase::Client::ExternalAddressesApi).to receive(:new).and_return(external_addresses_api)
    allow(Coinbase::Client::StakeApi).to receive(:new).and_return(stake_api)
    allow(Coinbase::Asset).to receive(:fetch).and_return(
      Coinbase::Asset.from_model(eth_asset)
    )
    allow(stake_api).to receive(:get_staking_context).and_return(staking_context)
  end

  describe '#initialize' do
    it 'initializes a new Address' do
      expect(address).to be_a(Coinbase::ExternalAddress)
    end
  end

  describe '#network_id' do
    it 'returns the network ID' do
      expect(address.network_id).to eq(network_id)
    end
  end

  describe '#id' do
    it 'returns the address ID' do
      expect(address.id).to eq(address_id)
    end
  end

  describe '#balances' do
    let(:response) do
      Coinbase::Client::AddressBalanceList.new(
        data: [
          Coinbase::Client::Balance.new(amount: '1000000000000000000', asset: eth_asset),
          Coinbase::Client::Balance.new(amount: '5000000000', asset: usdc_asset),
          Coinbase::Client::Balance.new(amount: '3000000000000000000', asset: weth_asset)
        ]
      )
    end

    before do
      allow(external_addresses_api)
        .to receive(:list_external_address_balances)
        .with(normalized_network_id, address_id)
        .and_return(response)
    end

    it 'returns a hash with balances' do
      expect(address.balances).to eq(
        eth: BigDecimal('1'),
        usdc: BigDecimal('5000'),
        weth: BigDecimal('3')
      )
    end

    it 'lists external address balances' do
      address.balances

      expect(external_addresses_api)
        .to have_received(:list_external_address_balances)
        .with(normalized_network_id, address_id)
    end
  end

  shared_examples 'it builds a staking operation' do |operation|
    let(:transaction) { instance_double('Coinbase::Client::Transaction') }
    let(:staking_operation) do
      instance_double(
        'Coinbase::Client::StakingOperation',
        transaction: transaction
      )
    end

    before(:each) do
      allow(stake_api).to receive(:build_staking_operation).and_return(staking_operation)
      allow(Coinbase::StakingOperation).to receive(:new)
      allow(stake_api).to receive(:get_staking_context).and_return(staking_context)
    end

    it 'creates a new staking_api_client' do
      subject
      expect(Coinbase::Client::StakeApi).to have_received(:new)
    end

    it 'calls build_staking_operation' do
      subject
      expect(stake_api).to have_received(:build_staking_operation).with(
        asset_id: eth_asset.asset_id,
        address_id: id,
        action: operation,
        network_id: 'ethereum-mainnet',
        options: { amount: (10**18).to_s, mode: mode }
      )
    end

    it 'creates a new StakingOperation' do
      subject
      expect(Coinbase::StakingOperation).to have_received(:new).with(staking_operation)
    end

    context "when the amount is less than the #{operation} minimum" do
      let(:"#{operation}_balance") { 0 }

      it 'raises an error' do
        expect { subject }.to raise_error(Coinbase::InsufficientFundsError)
      end
    end
  end

  describe '#build_stake_operation' do
    subject { address.build_stake_operation(1, eth_asset.asset_id, mode: mode) }

    it_behaves_like 'it builds a staking operation', 'stake'
  end

  describe '#build_unstake_operation' do
    subject { address.build_unstake_operation(1, eth_asset.asset_id, mode: mode) }

    it_behaves_like 'it builds a staking operation', 'unstake'
  end

  describe '#build_claim_stake_operation' do
    subject { address.build_claim_stake_operation(1, eth_asset.asset_id, mode: mode) }

    it_behaves_like 'it builds a staking operation', 'claim_stake'
  end

  describe '#balance' do
    let(:response) do
      Coinbase::Client::Balance.new(amount: '1000000000000000000', asset: eth_asset)
    end

    before do
      allow(external_addresses_api)
        .to receive(:get_external_address_balance)
        .with(normalized_network_id, address_id, primary_denomination)
        .and_return(response)
    end

    context 'when the asset_id is :eth' do
      let(:asset_id) { :eth }
      let(:primary_denomination) { 'eth' }

      it 'returns the correct ETH balance' do
        expect(address.balance(:eth)).to eq BigDecimal('1')
      end
    end

    context 'when the asset_id is :gwei' do
      let(:asset_id) { :gwei }
      let(:primary_denomination) { 'eth' }

      it 'returns the correct Gwei balance' do
        expect(address.balance(:gwei)).to eq BigDecimal('1_000_000_000')
      end
    end

    context 'when the asset_id is :wei' do
      let(:asset_id) { :wei }
      let(:primary_denomination) { 'eth' }

      it 'returns the correct Wei balance' do
        expect(address.balance(:wei)).to eq BigDecimal('1_000_000_000_000_000_000')
      end
    end

    context 'when the asset id is a non-eth denomination' do
      let(:asset_id) { :other }
      let(:primary_denomination) { 'other' }
      let(:decimals) { 7 }
      let(:other_asset) do
        Coinbase::Client::Asset.new(network_id: 'base-sepolia', asset_id: 'other', decimals: decimals)
      end
      let(:response) do
        Coinbase::Client::Balance.new(amount: '1000000000000000000', asset: other_asset)
      end

      it 'returns the correct balance' do
        expect(address.balance(:other)).to eq BigDecimal('100_000_000_000')
      end
    end

    context 'when there is no response' do
      let(:response) { nil }
      let(:asset_id) { :eth }
      let(:primary_denomination) { 'eth' }

      it 'returns 0' do
        expect(address.balance(:eth)).to eq BigDecimal('0')
      end
    end
  end

  describe '#faucet' do
    let(:request) { double('Request', transaction: transaction) }
    let(:tx_hash) { '0xdeadbeef' }
    let(:faucet_tx) do
      instance_double('Coinbase::Client::FaucetTransaction', transaction_hash: tx_hash)
    end

    context 'when the request is successful' do
      subject(:faucet_response) { address.faucet }

      before do
        expect(external_addresses_api)
          .to receive(:request_external_faucet_funds)
          .with(normalized_network_id, address_id)
          .and_return(faucet_tx)
      end

      it 'requests funds from the faucet and returns the faucet transaction' do
        expect(faucet_response).to be_a(Coinbase::FaucetTransaction)
        expect(faucet_response.transaction_hash).to eq(tx_hash)
      end
    end

    context 'when the request is unsuccesful' do
      before do
        expect(external_addresses_api)
          .to receive(:request_external_faucet_funds)
          .with(normalized_network_id, address_id)
          .and_raise(api_error)
      end

      context 'when the faucet limit is reached' do
        let(:api_error) do
          Coinbase::Client::ApiError.new(
            code: 429,
            response_body: {
              'code' => 'faucet_limit_reached',
              'message' => 'failed to claim funds - address likely has already claimed in the past 24 hours'
            }.to_json
          )
        end

        it 'raises a FaucetLimitReachedError' do
          expect { address.faucet }.to raise_error(::Coinbase::FaucetLimitReachedError)
        end
      end

      context 'when the request fails unexpectedly' do
        let(:api_error) do
          Coinbase::Client::ApiError.new(
            code: 500,
            response_body: {
              'code' => 'internal',
              'message' => 'unexpected error occurred while requesting faucet funds'
            }.to_json
          )
        end

        it 'raises an internal error' do
          expect { address.faucet }.to raise_error(::Coinbase::InternalError)
        end
      end
    end
  end

  shared_examples 'it called staking context balances' do
    it 'creates a new staking_api_client' do
      subject

      expect(Coinbase::Client::StakeApi).to have_received(:new)
    end

    it 'calls get_staking_context' do
      subject

      expect(stake_api).to have_received(:get_staking_context).with(
        asset_id: eth_asset.asset_id,
        address_id: id,
        network_id: 'ethereum-mainnet',
        options: {
          mode: mode
        }
      )
    end
  end

  describe '#get_staking_balances' do
    subject { address.get_staking_balances(eth_asset.asset_id, mode: mode) }

    it 'returns the staking balances' do
      expect(subject).to eq(
        stakeable_balance: stake_balance,
        unstakeable_balance: unstake_balance,
        claimable_balance: claim_stake_balance
      )
    end

    it_behaves_like 'it called staking context balances'
  end

  describe '#get_stakeable_balance' do
    subject { address.get_stakeable_balance(eth_asset.asset_id, mode: mode) }

    it_behaves_like 'it called staking context balances'

    it { is_expected.to eq(stake_balance) }
  end

  describe '#get_unstakeable_balance' do
    subject { address.get_unstakeable_balance(eth_asset.asset_id, mode: mode) }

    it_behaves_like 'it called staking context balances'

    it { is_expected.to eq(unstake_balance) }
  end

  describe '#get_claimable_balance' do
    subject { address.get_claimable_balance(eth_asset.asset_id, mode: mode) }

    it_behaves_like 'it called staking context balances'

    it { is_expected.to eq(claim_stake_balance) }
  end

  describe '#staking_rewards' do
    it 'calls list on StakingReward' do
      start_time = Time.now
      expect(Coinbase::StakingReward).to receive(:list).with(
        network_id,
        eth_asset.asset_id,
        [id],
        start_time,
        start_time,
        format: :usd
      )
      subject.staking_rewards(eth_asset.asset_id, start_time, start_time)
    end
  end
end
