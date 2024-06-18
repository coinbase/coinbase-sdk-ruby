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

    private

    def addresses_api
      @addresses_api ||= Coinbase::Client::AddressesApi.new(Coinbase.configuration.api_client)
    end
  end
end
