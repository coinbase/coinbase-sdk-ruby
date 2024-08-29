# frozen_string_literal: true

module Coinbase
  # A representation of a blockchain Address, which is a user-controlled account on a Network.
  # Addresses are used to send and receive Assets.
  class Address
    attr_reader :network, :id

    # Returns a new Address object.
    # @param network [Coinbase::Network, Symbol] The Network or Network ID
    # @param id [String] The onchain Address ID
    def initialize(network, id)
      @network = Coinbase::Network.from_id(network)
      @id = id
    end

    # Returns a String representation of the Address.
    # @return [String] a String representation of the Address
    def to_s
      Coinbase.pretty_print_object(self.class, id: id, network_id: network.id)
    end

    # Same as to_s.
    # @return [String] a String representation of the Address
    def inspect
      to_s
    end

    # Returns true if the Address can sign transactions.
    # @return [Boolean] true if the Address can sign transactions
    def can_sign?
      false
    end

    # Returns the balances of the Address.
    # @return [BalanceMap] The balances of the Address, keyed by asset ID. Ether balances are denominated
    #  in ETH.
    def balances
      response = Coinbase.call_api do
        addresses_api.list_external_address_balances(network.normalized_id, id)
      end

      Coinbase::BalanceMap.from_balances(response.data)
    end

    # Returns the balance of the provided Asset.
    # @param asset_id [Symbol] The Asset to retrieve the balance for
    # @return [BigDecimal] The balance of the Asset
    def balance(asset_id)
      response = Coinbase.call_api do
        addresses_api.get_external_address_balance(
          network.normalized_id,
          id,
          Coinbase::Asset.primary_denomination(asset_id).to_s
        )
      end

      return BigDecimal('0') if response.nil?

      Coinbase::Balance.from_model_and_asset_id(response, asset_id).amount
    end

    # Enumerates the historical balances for a given asset belonging of address.
    # The result is an enumerator that lazily fetches from the server, and can be iterated over,
    # converted to an array, etc...
    # @return [Enumerable<Coinbase::HistoricalBalance>] Enumerator that returns historical_balance
    def historical_balances(asset_id)
      Coinbase::Pagination.enumerate(
        ->(page) { list_page(asset_id, page) }
      ) do |historical_balance|
        Coinbase::HistoricalBalance.from_model(historical_balance)
      end
    end

    # Requests funds for the address from the faucet and returns the faucet transaction.
    # This is only supported on testnet networks.
    # @param asset_id [Symbol] The ID of the Asset to transfer to the wallet.
    # @return [Coinbase::FaucetTransaction] The successful faucet transaction
    # @raise [Coinbase::FaucetLimitReachedError] If the faucet limit has been reached for the address or user.
    # @raise [Coinbase::Client::ApiError] If an unexpected error occurs while requesting faucet funds.
    def faucet(asset_id: nil)
      opts = { asset_id: asset_id }.compact

      Coinbase.call_api do
        Coinbase::FaucetTransaction.new(
          addresses_api.request_external_faucet_funds(network.normalized_id, id, opts)
        )
      end
    end

    # Builds a stake operation for the supplied asset. The stake operation
    # may take a few minutes to complete in the case when infrastructure is spun up.
    # @param amount [Integer,String,BigDecimal] The amount of the asset to stake
    # @param asset_id [Symbol] The asset to stake
    # @param mode [Symbol] The staking mode. Defaults to :default.
    # @param options [Hash] (Optional) Additional options for the stake operation. ({StakingOperation#build see_more})
    # @return [Coinbase::StakingOperation] The stake operation
    def build_stake_operation(amount, asset_id, mode: :default, options: {})
      validate_can_perform_staking_action!(amount, asset_id, 'stakeable_balance', mode, options)

      StakingOperation.build(amount, network, asset_id, id, 'stake', mode, options)
    end

    # Builds an unstake operation for the supplied asset.
    # @param amount [Integer,String,BigDecimal] The amount of the asset to unstake
    # @param asset_id [Symbol] The asset to unstake
    # @param mode [Symbol] The staking mode. Defaults to :default.
    # @param options [Hash] (Optional) Additional options for the unstake operation. ({StakingOperation#build see_more})
    # @return [Coinbase::StakingOperation] The unstake operation
    def build_unstake_operation(amount, asset_id, mode: :default, options: {})
      validate_can_perform_staking_action!(amount, asset_id, 'unstakeable_balance', mode, options)

      StakingOperation.build(amount, network, asset_id, id, 'unstake', mode, options)
    end

    # Builds a claim_stake operation for the supplied asset.
    # @param amount [Integer,String,BigDecimal] The amount of the asset to claim
    # @param asset_id [Symbol] The asset to claim
    # @param mode [Symbol] The staking mode. Defaults to :default.
    # @param options [Hash] (Optional) Additional options for the claim_stake operation.
    #   ({StakingOperation#build see_more})
    # @return [Coinbase::StakingOperation] The claim_stake operation
    def build_claim_stake_operation(amount, asset_id, mode: :default, options: {})
      validate_can_perform_staking_action!(amount, asset_id, 'claimable_balance', mode, options)

      StakingOperation.build(amount, network, asset_id, id, 'claim_stake', mode, options)
    end

    # Retrieves the balances used for staking for the supplied asset.
    # @param asset_id [Symbol] The asset to retrieve staking balances for
    # @param mode [Symbol] The staking mode. Defaults to :default.
    # @param options [Hash] (Optional) Additional options for fetching the staking balances
    # @option options [String] (Optional) :validator_pub_keys List of comma separated validator public keys to retrieve
    #   staking balances for. (default: all validators) [asset_id: :eth, mode: :native]
    # @return [Hash] The staking balances
    # @return [BigDecimal] :stakeable_balance The amount of the asset that can be staked
    # @return [BigDecimal] :unstakeable_balance The amount of the asset that is currently staked and cannot be unstaked
    # @return [BigDecimal] :claimable_balance The amount of the asset that can be claimed
    def staking_balances(asset_id, mode: :default, options: {})
      context_model = Coinbase.call_api do
        stake_api.get_staking_context(
          {
            asset_id: asset_id,
            network_id: network.normalized_id,
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
    # @param options [Hash] Additional options for fetching the stakeable balance
    # @return [BigDecimal] The stakeable balance
    def stakeable_balance(asset_id, mode: :default, options: {})
      staking_balances(asset_id, mode: mode, options: options)[:stakeable_balance]
    end

    # Retrieves the unstakeable balance for the supplied asset.
    # @param asset_id [Symbol] The asset to retrieve the unstakeable balance for
    # @param mode [Symbol] The staking mode. Defaults to :default.
    # @param options [Hash] Additional options for fetching the unstakeable balance
    # @return [BigDecimal] The unstakeable balance
    def unstakeable_balance(asset_id, mode: :default, options: {})
      staking_balances(asset_id, mode: mode, options: options)[:unstakeable_balance]
    end

    # Retrieves the claimable balance for the supplied asset.
    # @param asset_id [Symbol] The asset to retrieve the claimable balance for
    # @param mode [Symbol] The staking mode. Defaults to :default.
    # @param options [Hash] Additional options for fetching the claimable balance
    # @return [BigDecimal] The claimable balance
    def claimable_balance(asset_id, mode: :default, options: {})
      staking_balances(asset_id, mode: mode, options: options)[:claimable_balance]
    end

    # Lists the staking rewards for the address.
    # @param asset_id [Symbol] The asset to retrieve staking rewards for
    # @param start_time [Time] The start time for the rewards. Defaults to 1 week ago.
    # @param end_time [Time] The end time for the rewards. Defaults to the current time.
    # @param format [Symbol] The format to return the rewards in. Defaults to :usd.
    # @return [Enumerable<Coinbase::StakingReward>] The staking rewards
    def staking_rewards(asset_id, start_time: DateTime.now.prev_week(1), end_time: DateTime.now, format: :usd)
      StakingReward.list(
        network,
        asset_id,
        [id],
        start_time: start_time,
        end_time: end_time,
        format: format
      )
    end

    # Fetches the historical staking balances for the address.
    # @param asset_id [Symbol] The asset to retrieve staking rewards for
    # @param start_time [Time] The start time for the rewards. Defaults to 1 week ago.
    # @param end_time [Time] The end time for the rewards. Defaults to the current time.
    # @return [Enumerable<Coinbase::StakingBalance>] The staking rewards
    def historical_staking_balances(asset_id, start_time: DateTime.now.prev_week(1), end_time: DateTime.now)
      StakingBalance.list(
        network,
        asset_id,
        id,
        start_time: start_time,
        end_time: end_time
      )
    end

    private

    def validate_can_perform_staking_action!(amount, asset_id, balance_type, mode, options)
      current_staking_balance = staking_balances(asset_id, mode: mode, options: options)[balance_type.to_sym]
      raise InsufficientFundsError.new(amount, current_staking_balance) unless current_staking_balance >= amount
    end

    def addresses_api
      @addresses_api ||= Coinbase::Client::ExternalAddressesApi.new(Coinbase.configuration.api_client)
    end

    def stake_api
      @stake_api ||= Coinbase::Client::StakeApi.new(Coinbase.configuration.api_client)
    end

    def list_page(asset_id, page)
      addresses_api.list_address_historical_balance(
        network.normalized_id,
        id,
        Coinbase::Asset.primary_denomination(asset_id).to_s,
        { limit: DEFAULT_PAGE_LIMIT, page: page }
      )
    end
  end
end
