# frozen_string_literal: true

require 'date'

module Coinbase
  # A representation of a staking balance on a network for a given asset.
  class StakingBalance
    class << self
      # Returns a list of StakingBalance for the provided network, asset, and addresses.
      # @param network_id [Symbol] The network ID
      # @param asset_id [Symbol] The asset ID
      # @param address_id [String] The address ID
      # @param start_time [Time] The start time. Defaults to one month ago.
      # @param end_time [Time] The end time. Defaults to the current time.
      # @return [Enumerable<Coinbase::StakingBalance>] The staking balances
      def list(network_id, asset_id, address_id, start_time: DateTime.now.prev_month(1), end_time: DateTime.now)
        Coinbase::Pagination.enumerate(
          ->(page) { list_page(network_id, asset_id, address_id, start_time, end_time, page) }
        ) do |staking_balance|
          new(staking_balance)
        end
      end

      def stake_api
        Coinbase::Client::StakeApi.new(Coinbase.configuration.api_client)
      end

      def list_page(network_id, asset_id, address_id, start_time, end_time, page)
        stake_api.fetch_historical_staking_balances(
          Coinbase.normalize_network(network_id),
          asset_id,
          address_id,
          start_time.iso8601,
          end_time.iso8601,
          { next_page: page }
        )
      end
    end

    # Returns a new StakingBalance object.
    # @param model [Coinbase::Client::StakingBalance] The underlying StakingBalance object
    def initialize(model)
      @model = model
    end

    # Returns the date of the StakingBalance.
    # @return [Time] The date
    def date
      @model.date
    end

    # Returns the onchain address of the StakingBalance.
    # @return [Time] The onchain address
    def address
      @model.address
    end

    # Returns the bonded stake as a Balance
    # @return [Balance] The bonded stake
    def bonded_stake
      @bonded_stake ||= Balance.from_model(@model.bonded_stake)
    end

    # Returns the unbonded balance as a Balance
    # @return [Balance] The unbonded balance
    def unbonded_balance
      @unbonded_balance ||= Balance.from_model(@model.unbonded_balance)
    end

    # Returns the participant type of the StakingBalance.
    # @return [String] The participant type
    def participant_type
      @model.participant_type
    end

    # Returns a string representation of the StakingBalance.
    # @return [String] a string representation of the StakingBalance
    def to_s
      "Coinbase::StakingBalance{date: '#{date}' address: '#{address}'}"
    end

    # Same as to_s.
    # @return [String] a string representation of the StakingBalance
    def inspect
      to_s
    end
  end
end
