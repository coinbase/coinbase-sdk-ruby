# frozen_string_literal: true

describe Coinbase::StakingReward do
  let(:network_id) { :network_id }
  let(:asset_id) { :asset_id }
  let(:asset) { instance_double(Coinbase::Asset) }
  let(:start_time) { Time.now }
  let(:end_time) { Time.now }
  let(:address_ids) { %w[address_id] }
  let(:stake_api) { instance_double(Coinbase::Client::StakeApi) }
  let(:format) { :usd }
  let(:has_more) { false }
  let(:staking_reward_model) do
    instance_double(Coinbase::Client::StakingReward, amount: 100, date: '2024-07-17', address_id: 'some-address')
  end

  before do
    allow(Coinbase::Asset).to receive(:fetch).and_return(asset)
    allow(Coinbase::Client::StakeApi).to receive(:new).and_return(stake_api)
    allow(stake_api).to receive(:fetch_staking_rewards).and_return(
      instance_double(Coinbase::Client::FetchStakingRewards200Response, data: [staking_reward_model], has_more: true,
                                                                        next_page: 'next_page'),
      instance_double(Coinbase::Client::FetchStakingRewards200Response, data: [], has_more: false)
    )
  end

  describe '.list' do
    subject(:list) do
      described_class.list(
        network_id, asset_id,
        address_ids,
        start_time: start_time,
        end_time: end_time,
        format: format
      )
    end

    it 'loads the asset' do
      list.to_a

      expect(Coinbase::Asset).to have_received(:fetch).with(network_id, asset_id)
    end

    it 'fetches the first page of staking rewards' do
      list.to_a

      expect(stake_api).to have_received(:fetch_staking_rewards).with(
        network_id: 'network-id',
        asset_id: asset_id,
        address_ids: address_ids,
        start_time: start_time.iso8601,
        end_time: end_time.iso8601,
        format: format,
        next_page: 'next_page'
      )
    end

    it 'fetches the last page of staking rewards' do
      list.to_a

      expect(stake_api).to have_received(:fetch_staking_rewards).with(
        network_id: 'network-id',
        asset_id: asset_id,
        address_ids: address_ids,
        start_time: start_time.iso8601,
        end_time: end_time.iso8601,
        format: format,
        next_page: nil
      )
    end

    it 'returns an enumerator' do
      expect(list).to be_an(Enumerator)
    end
  end

  describe '#amount' do
    subject(:amount) { staking_reward.amount }

    let(:staking_reward) { described_class.new(staking_reward_model, asset, format) }

    it 'returns the amount in USD' do
      expect(staking_reward.amount).to eq(BigDecimal('1'))
    end

    context 'when the format is not USD' do
      let(:format) { :native }
      let(:atomic_amount) { 101 }

      before do
        allow(asset).to receive(:from_atomic_amount).and_return(atomic_amount)
      end

      it 'returns the amount in the asset' do
        expect(staking_reward.amount).to eq(atomic_amount)
      end

      it 'calls from_atomic_amount on the asset' do
        staking_reward.amount

        expect(asset).to have_received(:from_atomic_amount).with(100)
      end
    end
  end

  describe '#date' do
    subject(:date) { staking_reward.date }

    let(:staking_reward) { described_class.new(staking_reward_model, asset, format) }

    it 'returns the date' do
      expect(staking_reward.date).to eq(staking_reward_model.date)
    end
  end

  describe '#address_id' do
    subject(:address_id) { staking_reward.address_id }

    let(:staking_reward) { described_class.new(staking_reward_model, asset, format) }

    it 'returns the address_id' do
      expect(staking_reward.address_id).to eq(staking_reward_model.address_id)
    end
  end

  describe '#to_s' do
    let(:staking_reward) { described_class.new(staking_reward_model, asset, format) }

    it 'returns a string representation of the StakingReward' do
      expected_string = "Coinbase::StakingReward{date: '#{staking_reward_model.date}' " \
                        "address_id: '#{staking_reward_model.address_id}' " \
                        "amount: '#{staking_reward.amount.to_f}'}"
      expect(staking_reward.to_s).to eq(expected_string)
    end
  end
end
