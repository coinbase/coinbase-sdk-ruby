# frozen_string_literal: true

module Coinbase
  # A representation of a staking reward.
  class StakingReward
    # Returns a new StakingReward object.
    class StakingRewardEnumerator
      include Enumerable

      def initialize(network_id, asset_id, address_ids, start_time, end_time, format)
        @network_id = network_id
        @asset_id = asset_id
        @address_ids = address_ids
        @start_time = start_time
        @end_time = end_time
        @format = format
        @rewards = []
        retreive_rewards
      end

      def each
        loop do
          @rewards.each do |reward|
            yield StakingReward.new(reward, @asset_id, @format)
          end
          break unless @model.has_more

          retreive_rewards
        end
      end

      private

      def retreive_rewards
        @model = Coinbase.call_api do
          req = {
            network_id: @network_id,
            asset_id: @asset_id,
            address_ids: @address_ids,
            start_time: @start_time.iso8601,
            end_time: @end_time.iso8601,
            format: @format
          }
          req[:next_page] = @model.next_page if @model&.next_page
          stake_api.fetch_staking_rewards(req)
        end
        @rewards += @model.data
      end

      def stake_api
        @stake_api ||= Coinbase::Client::StakeApi.new(Coinbase.configuration.api_client)
      end
    end

    def self.list(network_id, asset_id, address_ids, start_time, end_time, format: :usd)
      StakingRewardEnumerator.new(network_id, asset_id, address_ids, start_time, end_time, format)
    end

    def initialize(model, asset_id, format)
      @model = model
      @asset_id = asset_id
      @asset_id = :usd if format == :usd
    end

    def amount
      Asset.from_atomic_amount(@model.amount.to_i, @asset_id)
    end

    def date
      @model.date
    end

    def to_s
      "Coinbase::StakingReward{amount: '#{amount}'}"
    end

    def inspect
      to_s
    end
  end
end
