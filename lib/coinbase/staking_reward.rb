# frozen_string_literal: true

module Coinbase
  # A representation of a staking reward earned on a network for a given asset.
  class StakingReward
    # Returns a list of StakingRewards for the provided network, asset, and addresses.
    # @param network_id [Symbol] The network ID
    # @param asset_id [Symbol] The asset ID
    # @param address_ids [Array<String>] The address IDs
    # @param start_time [Time] The start time
    # @param end_time [Time] The end time
    # @param format [Symbol] The format to return the rewards in. (:usd, :native) Defaults to :usd.
    # @return [Enumerable<Coinbase::StakingReward>] The staking rewards
    def self.list(network_id, asset_id, address_ids, start_time, end_time, format: :usd)
      Enumerator.new do |yielder|
        asset = Coinbase.call_api do
          Asset.fetch(network_id, asset_id)
        end

        page = nil

        loop do
          resp = Coinbase.call_api do
            req = {
              network_id: Coinbase.normalize_network(network_id),
              asset_id: asset_id,
              address_ids: address_ids,
              start_time: start_time.iso8601,
              end_time: end_time.iso8601,
              format: format,
              next_page: page
            }
            stake_api.fetch_staking_rewards(req)
          end

          resp.data.each do |staking_reward|
            yielder << new(staking_reward, asset, format)
          end

          break unless resp.has_more
        end
      end
    end

    # Returns a new StakingReward object.
    # @param model [Coinbase::Client::StakingReward] The underlying StakingReward object
    def initialize(model, asset, format)
      @model = model
      @asset = asset
      @format = format
    end

    # Returns the amount of the StakingReward.
    # @return [BigDecimal] The amount
    def amount
      return BigDecimal(@model.amount.to_i) / BigDecimal(100) if @format == :usd

      @asset.from_atomic_amount(@model.amount.to_i)
    end

    # Returns the date of the StakingReward.
    # @return [Time] The date
    def date
      @model.date
    end

    # Returns a string representation of the StakingReward.
    # @return [String] a string representation of the StakingReward
    def to_s
      "Coinbase::StakingReward{amount: '#{amount}'}"
    end

    # Same as to_s.
    # @return [String] a string representation of the StakingReward
    def inspect
      to_s
    end

    def self.stake_api
      Coinbase::Client::StakeApi.new(Coinbase.configuration.api_client)
    end
  end
end
