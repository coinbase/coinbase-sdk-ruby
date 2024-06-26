# frozen_string_literal: true

module Coinbase
  # A representation of a blockchain Address, which is a user-controlled account on a Network. Addresses are used to
  # send and receive Assets.
  # @attr_reader [Symbol] network_id The Network ID
  # @attr_reader [String] id The onchain Address ID
  class Address
    attr_reader :network_id, :id

    # Returns a new Address object.
    # @param network_id [Symbol] The Network ID
    # @param id [String] The onchain Address ID
    def initialize(network_id, id)
      @network_id = Coinbase.to_sym(network_id)
      @id = id
    end

    # Returns a String representation of the Address.
    # @return [String] a String representation of the Address
    def to_s
      "Coinbase::Address{id: '#{id}', network_id: '#{network_id}'}"
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
      @addresses_api ||= Coinbase::Client::ExternalAddressesApi.new(Coinbase.configuration.api_client)
    end
  end
end
