# frozen_string_literal: true

shared_context 'with mocked staking_balances' do
  let(:stake_api) { instance_double(Coinbase::Client::StakeApi) }
  let(:stake_balance) { 100 }
  let(:unstake_balance) { 100 }
  let(:claim_stake_balance) { 100 }
  let(:eth_asset_model) do
    Coinbase::Client::Asset.new(network_id: normalized_network_id, asset_id: 'eth', decimals: 18)
  end
  let(:eth_asset) { Coinbase::Asset.from_model(eth_asset_model) }
  let(:staking_context) do
    instance_double(
      Coinbase::Client::StakingContext,
      context: instance_double(
        Coinbase::Client::PartialEthStakingContext,
        stakeable_balance: Coinbase::Client::Balance.new(
          amount: eth_asset.to_atomic_amount(stake_balance),
          asset: eth_asset_model
        ),
        unstakeable_balance: Coinbase::Client::Balance.new(
          amount: eth_asset.to_atomic_amount(unstake_balance),
          asset: eth_asset_model
        ),
        claimable_balance: Coinbase::Client::Balance.new(
          amount: eth_asset.to_atomic_amount(claim_stake_balance),
          asset: eth_asset_model
        )
      )
    )
  end

  before do
    allow(Coinbase::Client::StakeApi).to receive(:new).and_return(stake_api)
    allow(stake_api).to receive(:get_staking_context).and_return(staking_context)
  end
end

shared_examples 'an address that supports staking' do
  let(:network_id) { :ethereum_mainnet }
  let(:normalized_network_id) { 'ethereum-mainnet' }
  let(:mode) { :partial }
  let(:stake_api) { instance_double(Coinbase::Client::StakeApi) }
  let(:eth_asset_model) do
    Coinbase::Client::Asset.new(network_id: normalized_network_id, asset_id: 'eth', decimals: 18)
  end
  let(:eth_asset) { Coinbase::Asset.from_model(eth_asset_model) }

  before do
    allow(Coinbase::Client::StakeApi).to receive(:new).and_return(stake_api)
  end
  include_context 'with mocked staking_balances'

  shared_examples 'it builds a staking operation' do |operation|
    let(:transaction) { instance_double(Coinbase::Client::Transaction) }
    let(:staking_operation) do
      instance_double(
        Coinbase::Client::StakingOperation,
        status: :initialized,
        transactions: [transaction]
      )
    end

    before do
      allow(stake_api).to receive(:build_staking_operation).and_return(staking_operation)
      allow(Coinbase::StakingOperation).to receive(:new)
      allow(Coinbase::Asset).to receive(:fetch).and_return(eth_asset)
      allow(stake_api).to receive(:get_staking_context).and_return(staking_context)
    end

    it 'creates a new staking_api_client' do
      subject
      expect(Coinbase::Client::StakeApi).to have_received(:new)
    end

    it 'calls build_staking_operation' do
      subject
      expect(stake_api).to have_received(:build_staking_operation).with(
        asset_id: eth_asset_model.asset_id,
        address_id: address_id,
        action: operation,
        network_id: 'ethereum-mainnet',
        options: { amount: (10**18).to_s, mode: mode }
      )
    end

    it 'fetches the asset' do
      subject

      expect(Coinbase::Asset)
        .to have_received(:fetch)
        .with(:ethereum_mainnet, eth_asset_model.asset_id)
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
    subject { address.build_stake_operation(1, eth_asset_model.asset_id, mode: mode) }

    it_behaves_like 'it builds a staking operation', 'stake'
  end

  describe '#build_unstake_operation' do
    subject { address.build_unstake_operation(1, eth_asset_model.asset_id, mode: mode) }

    it_behaves_like 'it builds a staking operation', 'unstake'
  end

  describe '#build_claim_stake_operation' do
    subject { address.build_claim_stake_operation(1, eth_asset_model.asset_id, mode: mode) }

    it_behaves_like 'it builds a staking operation', 'claim_stake'
  end

  shared_examples 'it called staking context balances' do
    it 'creates a new staking_api_client' do
      subject

      expect(Coinbase::Client::StakeApi).to have_received(:new)
    end

    it 'calls staking_context' do
      subject

      expect(stake_api).to have_received(:get_staking_context).with(
        asset_id: eth_asset_model.asset_id,
        address_id: address_id,
        network_id: 'ethereum-mainnet',
        options: {
          mode: mode
        }
      )
    end
  end

  describe '#staking_balances' do
    subject { address.staking_balances(eth_asset_model.asset_id, mode: mode) }

    it 'returns the staking balances' do
      expect(subject).to eq(
        stakeable_balance: stake_balance,
        unstakeable_balance: unstake_balance,
        claimable_balance: claim_stake_balance
      )
    end

    it_behaves_like 'it called staking context balances'
  end

  describe '#stakeable_balance' do
    subject { address.stakeable_balance(eth_asset_model.asset_id, mode: mode) }

    it_behaves_like 'it called staking context balances'

    it { is_expected.to eq(stake_balance) }
  end

  describe '#unstakeable_balance' do
    subject { address.unstakeable_balance(eth_asset_model.asset_id, mode: mode) }

    it_behaves_like 'it called staking context balances'

    it { is_expected.to eq(unstake_balance) }
  end

  describe '#claimable_balance' do
    subject { address.claimable_balance(eth_asset_model.asset_id, mode: mode) }

    it_behaves_like 'it called staking context balances'

    it { is_expected.to eq(claim_stake_balance) }
  end

  describe '#staking_rewards' do
    it 'calls list on StakingReward' do
      start_time = Time.now
      expect(Coinbase::StakingReward).to receive(:list).with(
        network_id,
        eth_asset_model.asset_id,
        [address_id],
        start_time: start_time,
        end_time: start_time,
        format: :usd
      )
      subject.staking_rewards(eth_asset_model.asset_id, start_time: start_time, end_time: start_time)
    end
  end
end
