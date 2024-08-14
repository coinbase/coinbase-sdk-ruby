# frozen_string_literal: true

describe Coinbase::StakingBalance do
  let(:network_id) { 'network-id' }
  let(:asset_id) { 'asset_id' }
  let(:address_id) { 'address_id' }
  let(:start_time) { Time.now }
  let(:end_time) { Time.now }
  let(:stake_api) { instance_double(Coinbase::Client::StakeApi) }
  let(:staking_balance_model) { build(:staking_balance_model) }
  let(:staking_balance) { build(:staking_balance, model: staking_balance_model) }

  before do
    allow(Coinbase::Client::StakeApi).to receive(:new).and_return(stake_api)
    allow(stake_api).to receive(:fetch_historical_staking_balances).and_return(
      instance_double(Coinbase::Client::FetchHistoricalStakingBalances200Response, data: [staking_balance_model],
                                                                                   has_more: true,
                                                                                   next_page: 'next_page'),
      instance_double(Coinbase::Client::FetchHistoricalStakingBalances200Response, data: [], has_more: false)
    )
  end

  describe '.list' do
    subject(:list) do
      described_class.list(
        network_id, asset_id,
        address_id,
        start_time: start_time,
        end_time: end_time
      )
    end

    it 'fetches the staking balances' do
      list.to_a

      expect(stake_api).to have_received(:fetch_historical_staking_balances).with(
        network_id,
        asset_id,
        address_id,
        start_time.iso8601,
        end_time.iso8601,
        { next_page: nil }
      )
      expect(stake_api).to have_received(:fetch_historical_staking_balances).with(
        network_id,
        asset_id,
        address_id,
        start_time.iso8601,
        end_time.iso8601,
        { next_page: 'next_page' }
      )
    end

    it 'returns an enumerator' do
      expect(list).to be_an(Enumerator)
    end
  end

  describe '#date' do
    subject(:date) { staking_balance.date }

    it { is_expected.to eq(staking_balance_model.date) }
  end

  describe '#address' do
    subject(:address) { staking_balance.address }

    it { is_expected.to eq(staking_balance_model.address) }
  end

  describe '#bonded_stake' do
    subject(:bonded_stake) { staking_balance.bonded_stake }
    it { is_expected.to be_a(Coinbase::Balance) }

    it 'has the proper amount' do
      expect(bonded_stake.amount).to eq(Coinbase::Balance.from_model(staking_balance_model.bonded_stake).amount)
    end

    it 'has the proper asset' do
      expect(bonded_stake.asset.asset_id).to eq(
        Coinbase::Balance.from_model(staking_balance_model.bonded_stake).asset.asset_id
      )
    end
  end

  describe '#unbonded_balance' do
    subject(:unbonded_balance) { staking_balance.unbonded_balance }
    it { is_expected.to be_a(Coinbase::Balance) }

    it 'has the proper amount' do
      expect(unbonded_balance.amount).to eq(Coinbase::Balance.from_model(staking_balance_model.unbonded_balance).amount)
    end

    it 'has the proper asset' do
      expect(unbonded_balance.asset.asset_id).to eq(
        Coinbase::Balance.from_model(staking_balance_model.unbonded_balance).asset.asset_id
      )
    end
  end

  describe '#to_s' do
    it 'returns a string representation of the StakingBalance' do
      expected_string =
        "Coinbase::StakingBalance{date: '#{staking_balance_model.date}' address: '#{staking_balance_model.address}'}"
      expect(staking_balance.to_s).to eq(expected_string)
    end
  end
end
