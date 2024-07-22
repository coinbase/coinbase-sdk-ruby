# frozen_string_literal: true

require 'date'

module Coinbase
  # A representation of a staking reward earned on a network for a given asset.
  class StakingReward
    # Returns a list of StakingRewards for the provided network, asset, and addresses.
    # @param network_id [Symbol] The network ID
    # @param asset_id [Symbol] The asset ID
    # @param address_ids [Array<String>] The address IDs
    # @param start_time [Time] The start time. Defaults to one month ago.
    # @param end_time [Time] The end time. Defaults to the current time.
    # @param format [Symbol] The format to return the rewards in. (:usd, :native) Defaults to :usd.
    # @return [Enumerable<Coinbase::StakingReward>] The staking rewards
    def self.list(network_id, asset_id, address_ids, start_time: DateTime.now.prev_month(1), end_time: DateTime.now,
                  format: :usd)
      asset = Coinbase.call_api do
        Asset.fetch(network_id, asset_id)
      end
      Coinbase::Pagination.enumerate(
        ->(page) { list_page(network_id, asset_id, address_ids, start_time, end_time, page, format) }
      ) do |staking_reward|
        new(staking_reward, asset, format)
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

    # Returns the onchain address of the StakingReward.
    # @return [Time] The onchain address
    def address_id
      @model.address_id
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

    def self.list_page(network_id, asset_id, address_ids, start_time, end_time, page, format)
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
  end
end
