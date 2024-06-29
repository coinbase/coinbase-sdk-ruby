# frozen_string_literal: true

require_relative 'constants'
require 'bigdecimal'
require 'eth'
require 'json'

module Coinbase
  # A representation of a Send, which moves an amount of an Asset from
  # a user-controlled Wallet to another address. The fee is assumed to be paid
  # in the native Asset of the Network. Sends should be created through Wallet#send or
  # Address#send.
  class Send
    class << self
      # Creates a new Send object.
      # @param address_id [String] The Address ID of the sending Address
      # @param asset_id [Symbol] The Asset ID of the Asset to send
      # @param amount [BigDecimal] The amount of the Asset to send
      # @param destination [Coinbase::Destination, Coinbase::Wallet, Coinbase::Address, String] The Destination to which to send the Asset
      # @param network_id [Symbol] The Network ID of the Asset
      # @param wallet_id [String] (Optional) The Wallet ID of the sending Wallet
      # @return [Send] The new pending Send object
      def create(address_id:, asset_id:, amount:, destination:, network_id:, wallet_id: nil)
        asset = Asset.fetch(network_id, asset_id)

        model = Coinbase.call_api do
          sends_api.create_send(
            Coinbase.normalize_network(network_id),
            address_id,
            {
              amount: asset.to_atomic_amount(amount).to_i.to_s,
              asset_id: asset.primary_denomination.to_s,
              destination: Destination.new(destination, network_id: network_id).address_id,
              wallet_id: wallet_id
            }
          )
        end

        new(model)
      end

      def build(address_id:, asset_id:, amount:, destination:, network_id:)
        asset = Asset.fetch(network_id, asset_id)

        model = Coinbase.call_api do
          sends_api.build_send(
            Coinbase.normalize_network(network_id),
            address_id,
            asset.to_atomic_amount(amount).to_i.to_s,
            asset.primary_denomination.to_s,
            Destination.new(destination, network_id: network_id).address_id
          )
        end

        new(model)
      end

      def fetch(network_id, address_id, send_id)
        model = Coinbase.call_api do
          sends_api.get_send(Coinbase.normalize_network(network_id), address_id, send_id)
        end

        new(model)
      end

      private

      def sends_api
        Coinbase::Client::SendsApi.new(Coinbase.configuration.api_client)
      end
    end

    # Returns a new Send object. Do not use this method directly. Instead, use Wallet#send or
    # Address#send.
    # @param model [Coinbase::Client::ModelSend] The underlying Send object
    def initialize(model)
      raise unless model.is_a?(Coinbase::Client::ModelSend)

      @model = model
    end

    # Returns the Send ID, if the send is managed.
    # @return [String, void] The Send ID, if present.
    def id
      @model.send_id
    end

    # Returns the Network ID of the Send.
    # @return [Symbol] The Network ID
    def network_id
      Coinbase.to_sym(@model.network_id)
    end

    # Returns the Wallet ID of the Send, if the send is managed.
    # @return [String, void] The Wallet ID, if present.
    def wallet_id
      @model.wallet_id
    end

    # Returns the From Address ID of the Send.
    # @return [String] The From Address ID
    def from_address_id
      @model.address_id
    end

    # Returns the Destination Address ID of the Send.
    # @return [String] The Destination Address ID
    def destination_address_id
      @model.destination
    end

    def asset
      @asset ||= Coinbase::Asset.from_model(@model.asset)
    end

    # Returns the amount of the asset for the Send.
    # @return [BigDecimal] The amount of the asset
    def amount
      asset.from_atomic_amount(@model.amount)
    end

    # Returns the Send transaction.
    # @return [Coinbase::Transaction] The Send transaction
    def transaction
      @transaction ||= Coinbase::Transaction.new(@model.transaction)
    end

    # Returns the status of the Send.
    # @return [Symbol] The status
    def status
      transaction.status
    end

    # Returns the link to the transaction on the blockchain explorer.
    # @return [String] The link to the transaction on the blockchain explorer
    def transaction_link
      transaction.transaction_link
    end

    # Broadcasts the Send to the Network.
    # This raises an error if the Send is not signed.
    # @raise [RuntimeError] If the Send is not signed
    # @return [Send] The Send object
    def broadcast!
      raise TransactionNotSignedError unless transaction.signed?

      @model = Coinbase.call_api do
        sends_api.broadcast_send(
          Coinbase.normalize_network(network_id),
          from_address_id,
          id,
          { signed_payload: transaction.raw.hex }
        )
      end

      # Update memoized transaction.
      @transaction = Coinbase::Transaction.new(@model.transaction)

      self
    end

    # Reload reloads the Send model with the latest version from the server side.
    # @return [Send] The most recent version of Send from the server.
    def reload
      @model = Coinbase.call_api do
        sends_api.get_send(@model.network_id, from_address_id, id)
      end

      # Update memoized transaction.
      @transaction = Coinbase::Transaction.new(@model.transaction)

      self
    end

    # Waits until the Send is completed or failed by polling the Network at the given interval. Raises a
    # Timeout::Error if the Send takes longer than the given timeout.
    # @param interval_seconds [Integer] The interval at which to poll the Network, in seconds
    # @param timeout_seconds [Integer] The maximum amount of time to wait for the Send to complete, in seconds
    # @return [Send] The completed Send object
    def wait!(interval_seconds = 0.2, timeout_seconds = 20)
      start_time = Time.now

      loop do
        reload

        return self if transaction.terminal_state?

        raise Timeout::Error, 'Send timed out' if Time.now - start_time > timeout_seconds

        self.sleep interval_seconds
      end

      self
    end

    # Returns a String representation of the Send.
    # @return [String] a String representation of the Send
    def to_s
      "Coinbase::Send{send_id: '#{id}', network_id: '#{network_id}', " \
        "from_address_id: '#{from_address_id}', destination_address_id: '#{destination_address_id}', " \
        "asset_id: '#{asset.asset_id}', amount: '#{amount}', transaction_link: '#{transaction_link}', " \
        "status: '#{status}'}"
    end

    # Same as to_s.
    # @return [String] a String representation of the Send
    def inspect
      to_s
    end

    private

    def sends_api
      @sends_api ||= Coinbase::Client::SendsApi.new(Coinbase.configuration.api_client)
    end
  end
end
