# frozen_string_literal: true

require 'date'

module Coinbase
  # A representation of a blockchain Address that does not belong to a Coinbase::Wallet.
  # External addresses can be used to fetch balances, request funds from the faucet, etc.,
  # but cannot be used to sign transactions.
  class ExternalAddress < Address
    # Builds a stake operation for the supplied asset. The stake operation
    # may take a few minutes to complete in the case when infrastructure is spun up.
    # @param amount [Integer,String,BigDecimal] The amount of the asset to stake
    # @param asset_id [Symbol] The asset to stake
    # @param mode [Symbol] The staking mode. Defaults to :default.
    # @param options [Hash] Additional options for the stake operation
    # @return [Coinbase::StakingOperation] The stake operation
    def build_stake_operation(amount, asset_id, mode: :default, options: {})
      validate_can_stake!(amount, asset_id, mode, options)

      build_staking_operation(amount, asset_id, 'stake', mode: mode, options: options)
    end

    # Builds an unstake operation for the supplied asset.
    # @param amount [Integer,String,BigDecimal] The amount of the asset to unstake
    # @param asset_id [Symbol] The asset to unstake
    # @param mode [Symbol] The staking mode. Defaults to :default.
    # @param options [Hash] Additional options for the unstake operation
    # @return [Coinbase::StakingOperation] The unstake operation
    def build_unstake_operation(amount, asset_id, mode: :default, options: {})
      validate_can_unstake!(amount, asset_id, mode, options)

      build_staking_operation(amount, asset_id, 'unstake', mode: mode, options: options)
    end

    # Builds an claim_stake operation for the supplied asset.
    # @param amount [Integer,String,BigDecimal] The amount of the asset to claim
    # @param asset_id [Symbol] The asset to claim
    # @param mode [Symbol] The staking mode. Defaults to :default.
    # @param options [Hash] Additional options for the claim_stake operation
    # @return [Coinbase::StakingOperation] The claim_stake operation
    def build_claim_stake_operation(amount, asset_id, mode: :default, options: {})
      validate_can_claim_stake!(amount, asset_id, mode, options)

      build_staking_operation(amount, asset_id, 'claim_stake', mode: mode, options: options)
    end

    # Retrieves the balances used for staking for the supplied asset.
    # @param asset_id [Symbol] The asset to retrieve staking balances for
    # @param mode [Symbol] The staking mode. Defaults to :default.
    # @param options [Hash] Additional options for the staking operation
    # @return [Hash] The staking balances
    # @return [BigDecimal] :stakeable_balance The amount of the asset that can be staked
    # @return [BigDecimal] :unstakeable_balance The amount of the asset that is currently staked and cannot be unstaked
    # @return [BigDecimal] :claimable_balance The amount of the asset that can be claimed
    def staking_balances(asset_id, mode: :default, options: {})
      context_model = Coinbase.call_api do
        stake_api.get_staking_context(
          {
            asset_id: asset_id,
            network_id: Coinbase.normalize_network(network_id),
            address_id: id,
            options: {
              mode: mode
            }.merge(options)
          }
        )
      end.context

      {
        stakeable_balance: Coinbase::Balance.from_model_and_asset_id(
          context_model.stakeable_balance,
          asset_id
        ).amount,
        unstakeable_balance: Coinbase::Balance.from_model_and_asset_id(
          context_model.unstakeable_balance,
          asset_id
        ).amount,
        claimable_balance: Coinbase::Balance.from_model_and_asset_id(
          context_model.claimable_balance,
          asset_id
        ).amount
      }
    end

    # Retrieves the stakeable balance for the supplied asset.
    # @param asset_id [Symbol] The asset to retrieve the stakeable balance for
    # @param mode [Symbol] The staking mode. Defaults to :default.
    # @param options [Hash] Additional options for the staking operation
    # @return [BigDecimal] The stakeable balance
    def stakeable_balance(asset_id, mode: :default, options: {})
      staking_balances(asset_id, mode: mode, options: options)[:stakeable_balance]
    end

    # Retrieves the unstakeable balance for the supplied asset.
    # @param asset_id [Symbol] The asset to retrieve the unstakeable balance for
    # @param mode [Symbol] The staking mode. Defaults to :default.
    # @param options [Hash] Additional options for the staking operation
    # @return [BigDecimal] The unstakeable balance
    def unstakeable_balance(asset_id, mode: :default, options: {})
      staking_balances(asset_id, mode: mode, options: options)[:unstakeable_balance]
    end

    # Retrieves the claimable balance for the supplied asset.
    # @param asset_id [Symbol] The asset to retrieve the claimable balance for
    # @param mode [Symbol] The staking mode. Defaults to :default.
    # @param options [Hash] Additional options for the staking operation
    # @return [BigDecimal] The claimable balance
    def claimable_balance(asset_id, mode: :default, options: {})
      staking_balances(asset_id, mode: mode, options: options)[:claimable_balance]
    end

    # Lists the staking rewards for the address.
    # @param asset_id [Symbol] The asset to retrieve staking rewards for
    # @param start_time [Time] The start time for the rewards. Defaults to 1 month ago.
    # @param end_time [Time] The end time for the rewards. Defaults to the current time.
    # @param format [Symbol] The format to return the rewards in. Defaults to :usd.
    # @return [Enumerable<Coinbase::StakingReward>] The staking rewards
    def staking_rewards(asset_id, start_time: DateTime.now.prev_month(1), end_time: DateTime.now, format: :usd)
      StakingReward.list(
        network_id,
        asset_id,
        [id],
        start_time: start_time,
        end_time: end_time,
        format: format
      )
    end

    private

    def validate_can_stake!(amount, asset_id, mode, options)
      stakeable_balance = stakeable_balance(asset_id, mode: mode, options: options)

      raise InsufficientFundsError.new(amount, stakeable_balance) unless stakeable_balance >= amount
    end

    def validate_can_unstake!(amount, asset_id, mode, options)
      unstakeable_balance = unstakeable_balance(asset_id, mode: mode, options: options)

      raise InsufficientFundsError.new(amount, unstakeable_balance) unless unstakeable_balance >= amount
    end

    def validate_can_claim_stake!(amount, asset_id, mode, options)
      claimable_balance = claimable_balance(asset_id, mode: mode, options: options)

      raise InsufficientFundsError.new(amount, claimable_balance) unless claimable_balance >= amount
    end

    def build_staking_operation(amount, asset_id, action, mode: :default, options: {})
      operation_model = Coinbase.call_api do
        asset = Coinbase::Asset.fetch(network_id, asset_id)
        stake_api.build_staking_operation(
          {
            asset_id: asset.primary_denomination.to_s,
            address_id: id,
            action: action,
            network_id: Coinbase.normalize_network(network_id),
            options: {
              amount: asset.to_atomic_amount(amount).to_i.to_s,
              mode: mode
            }.merge(options)
          }
        )
      end

      StakingOperation.new(operation_model)
    end

    def stake_api
      @stake_api ||= Coinbase::Client::StakeApi.new(Coinbase.configuration.api_client)
    end
  end
end
