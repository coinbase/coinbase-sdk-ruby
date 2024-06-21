# frozen_string_literal: true

module Coinbase
  # A representation of a blockchain Address that do not belong to a Coinbase::Wallet.
  # External addresses can be used to fetch balances, request funds from the faucet, etc...,
  # but cannot be used to sign transactions.
  class ExternalAddress < Address
    # Returns the balances of the Address.
    # @return [BalanceMap] The balances of the Address, keyed by asset ID. Ether balances are denominated
    #  in ETH.
    def balances
      response = Coinbase.call_api do
        addresses_api.list_external_address_balances(Coinbase.normalize_network(network_id), id)
      end

      Coinbase::BalanceMap.from_balances(response.data)
    end

    # Returns the balance of the provided Asset.
    # @param asset_id [Symbol] The Asset to retrieve the balance for
    # @return [BigDecimal] The balance of the Asset
    def balance(asset_id)
      response = Coinbase.call_api do
        addresses_api.get_external_address_balance(
          Coinbase.normalize_network(network_id),
          id,
          Coinbase::Asset.primary_denomination(asset_id).to_s
        )
      end

      return BigDecimal('0') if response.nil?

      Coinbase::Balance.from_model_and_asset_id(response, asset_id).amount
    end

    # Requests funds for the address from the faucet and returns the faucet transaction.
    # This is only supported on testnet networks.
    # @return [Coinbase::FaucetTransaction] The successful faucet transaction
    # @raise [Coinbase::FaucetLimitReachedError] If the faucet limit has been reached for the address or user.
    # @raise [Coinbase::Client::ApiError] If an unexpected error occurs while requesting faucet funds.
    def faucet
      Coinbase.call_api do
        Coinbase::FaucetTransaction.new(
          addresses_api.request_external_faucet_funds(Coinbase.normalize_network(network_id), id)
        )
      end
    end

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

    # Retreives the balances used for staking for the supplied asset.
    # @param asset_id [Symbol] The asset to retrieve staking balances for
    # @param mode [Symbol] The staking mode. Defaults to :default.
    # @param options [Hash] Additional options for the staking operation
    # @return [Hash] The staking balances
    # @return [BigDecimal] :stakeable_balance The amount of the asset that can be staked
    # @return [BigDecimal] :unstakeable_balance The amount of the asset that is currently staked and cannot be unstaked
    # @return [BigDecimal] :claimable_balance The amount of the asset that can be claimed
    def get_staking_balances(asset_id, mode: :default, options: {})
      asset = Coinbase.call_api do
        Coinbase::Asset.fetch(network_id, asset_id)
      end

      context_model = Coinbase.call_api do
        stake_api.get_staking_context(
          {
            asset_id: asset_id,
            network_id: normalize_network(network_id),
            address_id: id,
            options: {
              mode: mode
            }.merge(options)
          }
        )
      end.context
      if context_model.stakeable_balance.empty? || context_model.stakeable_balance.nil?
        context_model.stakeable_balance = '0'
      end
      if context_model.unstakeable_balance.empty? || context_model.unstakeable_balance.nil?
        context_model.unstakeable_balance = '0'
      end
      if context_model.claimable_balance.empty? || context_model.claimable_balance.nil?
        context_model.claimable_balance = '0'
      end

      {
        stakeable_balance: asset.from_atomic_amount(context_model.stakeable_balance.to_i),
        unstakeable_balance: asset.from_atomic_amount(context_model.unstakeable_balance.to_i),
        claimable_balance: asset.from_atomic_amount(context_model.claimable_balance.to_i)
      }
    end

    # Retreives the stakeable balance for the supplied asset.
    # @param asset_id [Symbol] The asset to retrieve the stakeable balance for
    # @param mode [Symbol] The staking mode. Defaults to :default.
    # @param options [Hash] Additional options for the staking operation
    # @return [BigDecimal] The stakeable balance
    def get_stakeable_balance(asset_id, mode: :default, options: {})
      get_staking_balances(asset_id, mode: mode, options: options)[:stakeable_balance]
    end

    # Retreives the unstakeable balance for the supplied asset.
    # @param asset_id [Symbol] The asset to retrieve the unstakeable balance for
    # @param mode [Symbol] The staking mode. Defaults to :default.
    # @param options [Hash] Additional options for the staking operation
    # @return [BigDecimal] The unstakeable balance
    def get_unstakeable_balance(asset_id, mode: :default, options: {})
      get_staking_balances(asset_id, mode: mode, options: options)[:unstakeable_balance]
    end

    # Retreives the claimable balance for the supplied asset.
    # @param asset_id [Symbol] The asset to retrieve the claimable balance for
    # @param mode [Symbol] The staking mode. Defaults to :default.
    # @param options [Hash] Additional options for the staking operation
    # @return [BigDecimal] The claimable balance
    def get_claimable_balance(asset_id, mode: :default, options: {})
      get_staking_balances(asset_id, mode: mode, options: options)[:claimable_balance]
    end

    # Lists the staking rewards for the address.
    # @param asset_id [Symbol] The asset to retrieve staking rewards for
    # @param start_time [Time] The start time for the rewards
    # @param end_time [Time] The end time for the rewards
    # @param format [Symbol] The format to return the rewards in. Defaults to :usd.
    # @return [Enumerable<Coinbase::StakingReward>] The staking rewards
    def staking_rewards(asset_id, start_time, end_time, format: :usd)
      StakingReward.list(network_id, asset_id, [id], start_time, end_time, format: format)
    end

    private

    def addresses_api
      @addresses_api ||= Coinbase::Client::ExternalAddressesApi.new(Coinbase.configuration.api_client)
    end

    def validate_can_stake!(amount, asset_id, mode, options)
      stakeable_balance = get_stakeable_balance(asset_id, mode: mode, options: options)

      raise InsufficientFundsError.new(amount, stakeable_balance) unless stakeable_balance >= amount
    end

    def validate_can_unstake!(amount, asset_id, mode, options)
      unstakeable_balance = get_unstakeable_balance(asset_id, mode: mode, options: options)

      raise InsufficientFundsError.new(amount, unstakeable_balance) unless unstakeable_balance >= amount
    end

    def validate_can_claim_stake!(amount, asset_id, mode, options)
      claimable_balance = get_claimable_balance(asset_id, mode: mode, options: options)

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
            network_id: normalize_network(network_id),
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

    def normalize_network(network_id)
      network_id.to_s.gsub(/_/, '-')
    end
  end
end
