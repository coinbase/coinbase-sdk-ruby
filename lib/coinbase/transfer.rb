# frozen_string_literal: true

require_relative 'constants'
require 'bigdecimal'
require 'eth'
require 'json'

module Coinbase
  # A representation of a Transfer, which moves an amount of an Asset from
  # a user-controlled Wallet to another address. The fee is assumed to be paid
  # in the native Asset of the Network. Transfers should be created through Wallet#transfer or
  # Address#transfer.
  class Transfer
    # Returns a new Transfer object. Do not use this method directly. Instead, use Wallet#transfer or
    # Address#transfer.
    # @param model [Coinbase::Client::Transfer] The underlying Transfer object
    def initialize(model)
      raise unless model.is_a?(Coinbase::Client::Transfer)

      @model = model
    end

    # Returns the Transfer ID.
    # @return [String] The Transfer ID
    def id
      @model.transfer_id
    end

    # Returns the Network ID of the Transfer.
    # @return [Symbol] The Network ID
    def network_id
      Coinbase.to_sym(@model.network_id)
    end

    # Returns the Wallet ID of the Transfer.
    # @return [String] The Wallet ID
    def wallet_id
      @model.wallet_id
    end

    # Returns the From Address ID of the Transfer.
    # @return [String] The From Address ID
    def from_address_id
      @model.address_id
    end

    # Returns the Destination Address ID of the Transfer.
    # @return [String] The Destination Address ID
    def destination_address_id
      @model.destination
    end

    def asset
      @asset ||= Coinbase::Asset.from_model(@model.asset)
    end

    # Returns the Asset ID of the Transfer.
    # @return [Symbol] The Asset ID
    def asset_id
      @model.asset_id.to_sym
    end

    # Returns the amount of the asset for the Transfer.
    # @return [BigDecimal] The amount of the asset
    def amount
      BigDecimal(@model.amount) / BigDecimal(10).power(@model.asset.decimals)
    end

    # Returns the link to the transaction on the blockchain explorer.
    # @return [String] The link to the transaction on the blockchain explorer
    def transaction_link
      # TODO: Parameterize this by Network.
      "https://sepolia.basescan.org/tx/#{transaction_hash}"
    end

    # Returns the Unsigned Payload of the Transfer.
    # @return [String] The Unsigned Payload
    def unsigned_payload
      @model.unsigned_payload
    end

    # Returns the Signed Payload of the Transfer.
    # @return [String] The Signed Payload
    def signed_payload
      @model.signed_payload
    end

    # Returns the Transfer transaction.
    # @return [Coinbase::Transaction] The Transfer transaction
    def transaction
      @transaction ||= Coinbase::Transaction.new(@model.transaction)
    end

    # Returns the Transaction Hash of the Transfer.
    # @return [String] The Transaction Hash
    def transaction_hash
      @model.transaction_hash
    end

    # Returns the status of the Transfer.
    # @return [Symbol] The status
    def status
      transaction.status
    end

    # Reload reloads the Transfer model with the latest version from the server side.
    # @return [Transfer] The most recent version of Transfer from the server.
    def reload
      @model = Coinbase.call_api do
        transfers_api.get_transfer(wallet_id, from_address_id, id)
      end

      # Update memoized transaction.
      @transaction = Coinbase::Transaction.new(@model.transaction)

      self
    end

    # Waits until the Transfer is completed or failed by polling the Network at the given interval. Raises a
    # Timeout::Error if the Transfer takes longer than the given timeout.
    # @param interval_seconds [Integer] The interval at which to poll the Network, in seconds
    # @param timeout_seconds [Integer] The maximum amount of time to wait for the Transfer to complete, in seconds
    # @return [Transfer] The completed Transfer object
    def wait!(interval_seconds = 0.2, timeout_seconds = 20)
      start_time = Time.now

      loop do
        reload

        return self if transaction.terminal_state?

        raise Timeout::Error, 'Transfer timed out' if Time.now - start_time > timeout_seconds

        self.sleep interval_seconds
      end

      self
    end

    # Returns a String representation of the Transfer.
    # @return [String] a String representation of the Transfer
    def to_s
      "Coinbase::Transfer{transfer_id: '#{id}', network_id: '#{network_id}', " \
        "from_address_id: '#{from_address_id}', destination_address_id: '#{destination_address_id}', " \
        "asset_id: '#{asset_id}', amount: '#{amount}', transaction_link: '#{transaction_link}', " \
        "status: '#{status}'}"
    end

    # Same as to_s.
    # @return [String] a String representation of the Transfer
    def inspect
      to_s
    end

    private

    def transfers_api
      @transfers_api ||= Coinbase::Client::TransfersApi.new(Coinbase.configuration.api_client)
    end
  end
end
